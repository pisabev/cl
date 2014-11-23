part of forms;

class GridColumn {

    GridList grid;

    dynamic title = '';

    dynamic width;

    String key;

    int cell_index;

    dynamic filter;

    bool sortable = false;

    bool visible = true;

    bool send = true;

    Function type;

    Selector selector;

    TableCellElement header_title_cell, header_filter_cell;

    GridColumn(this.key);

    renderTitle() {
        var cont = new CJSElement(new DivElement())
            .setStyle({'position':'relative'})
            .appendTo(header_title_cell);
        if(title is String)
            cont.dom.text = title;
        else if (title is List) {
            title.forEach((el) {
                if(el is String)
                    cont.dom.text = el;
                else
                    cont.append(el);
            });
        } else
            cont.append(title);
        header_title_cell.append(cont.dom);
        if(sortable) {
            header_title_cell.style.paddingRight = '20px';
            var el = new CJSElement(new SpanElement())
                .setClass('ui-icon-arrow')
                .appendTo(cont);
            new CJSElement(new AnchorElement()).appendTo(el).addAction((e) {
                if (grid.order.isEmpty || grid.order['field'] != key || grid.order['way'] == 'DESC')
                    grid.setOrder(key, 'ASC');
                else
                    grid.setOrder(key, 'DESC');
                grid.order_el[key] = el;
            });
        }
        if(selector != null)
            header_title_cell.classes.add('highlighted');
        _setWidth();
    }

    _setWidth() {
        if(width != null) {
            header_title_cell.style.width = width;
        }
    }

    renderFilter() {
        if(filter is List) {
            var cont = new CJSElement(new DivElement())
                .setStyle({'position':'relative'})
                .appendTo(header_filter_cell);
            filter.forEach((f) => cont.append(f.dom));
        } else if (filter != null)
            header_filter_cell.append(filter.dom);
    }

}

class RowDataCell<T, E> {

    T grid;

    TableRowElement row;

    TableCellElement cell;

    E object;

    RowDataCell(this.grid, this.row, this.cell, this.object);

    render() => cell.text = object.toString();

    toJson() => object;

}

class RowFormDataCell extends RowDataCell {

    RowFormDataCell(grid, row, cell, object) : super(grid, row, cell, object);

    render() => _render(object, cell);

    _render(object, cell) {
        if(object is List) {
            var cont = new CJSElement(new DivElement())
                .setStyle({'position':'relative'})
                .appendTo(cell);
            object.forEach((f) => _render(f, cont));
        } else {
            if(object is Data && grid is GridData) {
                object.addHook(Data.hook_value, () => grid.rowChanged(row));
                object.addHook(Data.hook_require, grid.observer.getHook(Data.hook_require));
            }
            if (object is CJSElement)
                cell.append(object.dom);
            else if (object is Element)
                cell.append(object);
            else if (object is Data)
                return;
            else
                cell.text = object.toString();
        }
    }

    _getValue(object) {
        if(object is Data)
            return object.getValue();
        else if(object is List)
            return object.map((o) => _getValue(o)).toList();
        else if(object is CJSElement)
            return null;
        else
            return object;
    }

    toJson() => _getValue(object);

}

abstract class RenderBase {

    GridList grid;

    DocumentFragment frg;

    RenderBase(this.grid);

    Future renderIt(List data);
}

class Render extends RenderBase {

    Render(grid) : super (grid);

    renderIt (List data) {
        return new Future.sync(() {
            frg = document.createDocumentFragment();
            for (var i=0, len = data.length; i<len; i++)
                frg.append(grid.rowCreate(data[i]));
            grid.tbody.dom.append(frg);
            if(grid.num)
                grid.rowNumRerender();
        });
    }
}


class GridBase extends DataElement<TableElement> {
    CJSElement thead, tbody, tfoot;

    GridBase() : super (new CJSElement(new TableElement())) {
        thead = new CJSElement(dom.createTHead()).appendTo(this);
        tbody = new CJSElement(dom.createTBody()).appendTo(this);
        tfoot = new CJSElement(dom.createTFoot()).appendTo(this);
    }

    hideHeader () {
        thead.hide();
        return this;
    }

    showHeader () {
        thead.setStyle({'display':''});
        return this;
    }

    hideFooter () {
        tfoot.hide();
        return this;
    }

    showFooter () {
        tfoot.setStyle({'display':''});
        return this;
    }

    show () {
        setStyle({'display':''});
        return this;
    }

    rowCreate () {
        return tbody.dom.insertRow(-1);
    }

    cellCreate (TableRowElement row) {
        return row.insertCell(-1);
    }

    rowCreateBefore (TableRowElement row, [TableRowElement row_new]) {
        row_new = (row_new != null)? row_new : new TableRowElement();
        tbody.dom.insertBefore(row_new, row.nextElementSibling);
        return row_new;
    }

    rowRemove (TableRowElement row, [bool show = false]) {
        row.remove();
        if (!show && tbody.dom.childNodes.length == 0)
            hide();
        return this;
    }

    removeChilds() {
        empty();
        return this;
    }

    empty () {
        tbody.removeChilds();
        return this;
    }
}

class GridForm extends GridBase {
    Form form;
    bool _reg = true;

    GridForm (this.form) : super() {
        setClass('ui-table-form');
    }

    setRegister(bool reg) {
        _reg = reg;
        return this;
    }

    addRow (List arr) {
        var row = rowCreate();
        var fieldCell = cellCreate(row);
        var first = arr.removeAt(0);
        if (first != null) {
            if(arr.length > 0)
                fieldCell.className = 'label';
            _addEl(first, fieldCell, row);
            fieldCell = null;
        }
        arr.forEach((el) {
            if (el != null && fieldCell == null)
                fieldCell = cellCreate(row);
            _addEl(el, fieldCell, row);
        });
        return row;
    }

    _addEl (el, fieldCell, row) {
        if(el is List) {
            el.forEach((e) => _addEl(e, fieldCell, row));
        } else {
            if(el is Data && _reg)
                registerElement(el);
            new RowFormDataCell(this, row, fieldCell, el)..render();
        }
    }

    setValue(dynamic data, [bool silent = false]) {
        if(data is Map)
            form.setData(data);
        else
            form.clear();
        return this;
    }

    getValue() => form.toOBJ(true);

    registerElement(el) {
        el.addHook(Data.hook_value, observer.getHook(Data.hook_value));
        el.addHook(Data.hook_require, observer.getHook(Data.hook_require));
        form.add(el);
    }

}

class GridList extends GridBase {
    static const String hook_order = 'hook_order';
    static const String hook_row = 'hook_row';
    static const String hook_row_after = 'hook_row_after';
    static const String hook_render = 'hook_render';
    static const String hook_layout = 'hook_layout';

    Expando _exp = new Expando();

    TableRowElement row;
    bool num, drag;

    Map<String, GridColumn> map = new Map();

    Map order = new Map(), order_el = new Map();

    GridList () : super() {
        setClass('ui-table-list');
    }

    Map getRowMap(TableRowElement row) => _exp[row];

    setRowMap(TableRowElement row, Map o) => _exp[row] = o;

    addRowHook (Function func) => addHook(hook_row, func);

    addRowHookAfter (Function func) => addHook(hook_row_after, func);

    addHookRender (Function func) => addHook(hook_render, func);

    addHookLayout (Function func) => addHook(hook_layout, func);

    addHookOrder (Function func) => addHook(hook_order, func);

    initGridHeader(List<GridColumn> data) {
        row = new TableRowElement();
        TableRowElement rowh = thead.dom.insertRow(-1);

        if(this.num) {
            if(data.every((h) => h.key != 'position')) {
                List temp = new List();
                temp.add(new GridColumn('position')
                    ..title = ''
                    ..send = false);
                temp.addAll(data);
                data = temp;
            }
        }

        int i = 0;
        data.forEach((h) {
            map[h.key] = h;
            h.grid = this;
            if(h.visible) {
                h.header_title_cell = rowh.insertCell(-1);
                row.insertCell(-1);
                h.cell_index = i++;
            }
        });

        var row_filter;
        if(data.any((h) => h.filter != null)) {
            row_filter = thead.dom.insertRow(-1)
                ..className = 'ui-table-filter';
            data.forEach((h) {
                h.header_filter_cell = row_filter.insertCell(-1);
            });
        }

        data.forEach((h) {
            if(h.visible)
                h.renderTitle();
            if(h.filter != null)
                h.renderFilter();
            if(h.type == null)
                h.type = (grid, row, cell, object) => new RowFormDataCell(grid, row, cell, object);
        });

        return this;
    }

    initHeader(List<Map> data) {
        List d = new List();
        data.forEach((Map hrow) {
            var gc = new GridColumn(hrow['key']);
            if(hrow.containsKey('title'))
                gc.title = hrow['title'];
            if(hrow.containsKey('visible'))
                gc.visible = hrow['visible'];
            if(hrow.containsKey('sortable'))
                gc.sortable = hrow['sortable'];
            if(hrow.containsKey('filter'))
                gc.filter = hrow['filter'];
            if(hrow.containsKey('type'))
                gc.type = hrow['type'];
            if(hrow.containsKey('width'))
                gc.width = hrow['width'];
            if(hrow.containsKey('send'))
                gc.send = hrow['send'];
            if(hrow.containsKey('selector'))
                gc.selector = hrow['selector'];
            d.add(gc);
        });
        return initGridHeader(d);
    }

    setOrder (String key, String way) {
        order = {'field': key, 'way': way};
        order_el.forEach((k, v) => v.setClass('ui-icon-arrow'));
        var el = order_el[key];
        if(el != null)
            el.setClass((way == 'ASC')? 'ui-icon-asc' : 'ui-icon-desc');
        execHooks(hook_order);
        return this;
    }

    renderIt (List data, [RenderBase render]) {
        if(render == null)
            render = new Render(this);
        render.renderIt(data).then((_) {
            execHooks(hook_render);
            map.forEach((k, GridColumn gc) {
                if(gc.selector != null)
                    gc.selector.init(gc);
            });
        });
    }

    rowNumRerender() {
        if(this.num) {
            for (int i = 0, l = tbody.dom.childNodes.length; i < l; i++)
                tbody.dom.childNodes[i].cells[0].text = (i + 1).toString();
        }
    }

    rowSet (TableRowElement row, Map obj) {
        obj.forEach((k, v) {
            if(map.containsKey(k)) {
                GridColumn gc = map[k];
                obj[k] = gc.visible? (gc.type(this, row, row.cells[gc.cell_index], v)..render()) : v;
            }
        });
        if(this.num && !obj.containsKey('position')) {
            if(map['position'].visible) {
                row.cells[map['position'].cell_index].className = 'num';
                obj['position'] = map['position'].type(this, row, row.cells[map['position'].cell_index], 0);
            }
        }
        setRowMap(row, obj);
        return row;
    }

    rowCreate ([obj]) {
        var row = this.row.clone(true);
        if(drag)
            _setDraggable(row);
        execHooks(hook_row, [row, obj]);
        rowSet(row, obj);
        execHooks(hook_row_after, [row, obj]);
        return row;
    }

    rowToMap(row) {
        var m = new Map();
        getRowMap(row).forEach((k, dynamic dc) {
            if(dc is RowDataCell) {
                if (map[k].send)
                    m[k] = dc.toJson();
            } else
                m[k] = dc;
        });
        return m;
    }

    _setDraggable (row) {
        row.draggable = true;
        var el = new CJSElement(row);
        el.addAction((e) {
            e.dataTransfer.setData('text', getRowIndex(el.dom).toString());
            e.dataTransfer.effectAllowed = 'move';
        },'dragstart')
        .addAction((e) => el.addClass('ui-drag-over'),'dragenter')
        .addAction((e) => el.removeClass('ui-drag-over'),'dragleave')
        .addAction((e) {
            e.preventDefault();
            e.stopPropagation();
            e.dataTransfer.dropEffect = 'move';
        },'dragover')
        .addAction((e) {
            _rowSwap(int.parse(e.dataTransfer.getData('text')), getRowIndex(el.dom));
            e.preventDefault();
            e.stopPropagation();
        },'drop');
    }

    _rowSwap (int s_rownum, int t_rownum) {
        _numRow (num) => tbody.dom.childNodes[num];
        if(s_rownum == t_rownum)
            return 0;
        if (s_rownum > t_rownum)
            tbody.dom.insertBefore(_numRow(s_rownum), _numRow(t_rownum));
        else
            tbody.dom.insertBefore(_numRow(s_rownum), _numRow(t_rownum).nextElementSibling);
        rowNumRerender();
        return math.min(s_rownum, t_rownum);
    }

    getRowIndex (row) {
        return row.rowIndex - thead.dom.childNodes.length;
    }

    empty () {
        super.empty();
        return this;
    }

    get scrollTop => tbody.dom.scrollTop;

    set scrollTop(int scroll_top) => tbody.dom.scrollTop = scroll_top;

}

class GridListFixed extends GridList {
    var cont_head;
    var cont_body;

    var _focus_el;
    var _scroll_top;

    GridListFixed() : super() {
        addHookRender(fixTable);
        addHookLayout(() {fixReset(); fixTable();});
    }

    fixTable() {
        if(tbody.dom.childNodes.length == 0) {
            if(_focus_el != null)
                _focus_el.focus();
            return;
        }

        List widths = [];
        List widths2 = [];

        var width = getWidth();
        for (var i = 0; i < thead.dom.childNodes[0].childNodes.length; i++)
            widths.add(new CJSElement(thead.dom.childNodes[0].childNodes[i]).getWidth());
        for (var i = 0; i < tbody.dom.childNodes[0].childNodes.length; i++)
            widths2.add(new CJSElement(tbody.dom.childNodes[0].childNodes[i]).getWidth());

        var parent = new CJSElement(dom.parentNode);
        var table_in = new CJSElement(new TableElement());

        cont_head = new CJSElement(new DivElement()).setClass('ui-table-list shadow').append(table_in);
        cont_body = new CJSElement(new DivElement()).setStyle({'overflow':'auto', 'position': 'relative'})
            .addAction((e) {
                cont_head.dom.scrollLeft = cont_body.dom.scrollLeft;
            },'scroll')
            .append(this);
        parent.append(cont_head).append(cont_body);
        var scroll_bar = parent.dom.clientHeight < parent.dom.scrollHeight? utils.getScrollbarWidth() : 0;
        table_in.setWidth(width + scroll_bar).append(thead);
        setWidth(width);

        cont_body.setStyle({'height':'${parent.getHeight() - cont_head.getHeight()}px'});
        widths[widths.length - 1] += scroll_bar;

        for (var i = 0; i < thead.dom.childNodes[0].childNodes.length; i++)
            new CJSElement(thead.dom.childNodes[0].childNodes[i]).setStyle({'width':'${widths[i]}px'});
        for (var i = 0; i < tbody.dom.childNodes[0].childNodes.length; i++)
            new CJSElement(tbody.dom.childNodes[0].childNodes[i]).setStyle({'width':'${widths2[i]}px'});

        if(_focus_el != null)
            _focus_el.focus();

        scrollTop = _scroll_top;
    }

    fixReset() {
        _scroll_top = scrollTop;
        _focus_el = document.activeElement;
        if(cont_head != null && cont_head.dom.parentNode != null) {
            append(thead);
            new CJSElement(cont_head.dom.parentNode).append(this);
            cont_head.remove();
            cont_body.remove();
            setStyle({'width': '100%'});
            map.forEach((k, v) => v._setWidth());
        }
    }

    empty() {
        fixReset();
        super.empty();
        _scroll_top = 0;
        return this;
    }

    get scrollTop => cont_head != null? cont_body.dom.scrollTop : tbody.dom.scrollTop;

    set scrollTop(int scroll_top) {
        _scroll_top = scroll_top;
        cont_head != null?
            cont_body.dom.scrollTop = _scroll_top :
            tbody.dom.scrollTop = _scroll_top;
    }
}

class GridData extends GridList {
    List<TableRowElement> rows;
    Map<String, List> rows_send;

    bool full_data = false;

    GridData () {
        setClass('ui-table-grid');
        _initSendRows();
    }

    _initSendRows () => rows_send = {'insert': [],'update': [],'delete': []};

    _setCell(row, k, obj) {
        dynamic rd = getRowMap(row)[k];
        if(rd is RowDataCell) {
            rd.object = obj;
            rd.render();
        } else {
            getRowMap(row)[k] = obj;
        }
    }

    updateCell(row, k, obj) {
        _setCell(row, k, obj);
        rowChanged(row);
    }

    setValue (List arr, [bool silent = false]) {
        empty();
        if (arr != null && arr.length > 0) {
            renderIt(arr);
            show();
        } else {
            hide();
        }
        return this;
    }

    getValue([bool full = false]) {
        var data;
        if(full_data || full) {
            data = new List();
            tbody.dom.childNodes.forEach((row) => data.add(rowToMap(row)));
        } else {
            data = new Map();
            rows_send.forEach((k, v) {
                if(v.length > 0) {
                    v.forEach((row) {
                        if (data[k] == null)
                            data[k] = new List();
                        data[k].add(rowToMap(row));
                    });
                }
            });
        }
        return data;
    }

    getRequired () {
        var a = [];
        tbody.dom.childNodes.forEach((row) => getRowMap(row).forEach((k, dynamic dc) {
            if(dc is RowDataCell && dc.object is Data && !dc.object.isReady())
                a.add(dc.object);
        }));
        return a;
    }

    rowAdd (Map obj, [bool silent = false]) {
        var row = rowCreate(obj);
        rows_send['insert'].add(row);
        tbody.dom.append(row);
        if (!silent)
            execHooks(Data.hook_value);
        execHooks(GridList.hook_render);
        if(super.num)
            rowNumRerender();
        return row;
    }

    rowAddBefore (TableRowElement r, Map obj, [bool silent = false]) {
        var row = rowCreate(obj);
        rows_send['insert'].add(row);
        rowCreateBefore(r, row);
        if (!silent)
            execHooks(Data.hook_value);
        execHooks(GridList.hook_render);
        if(super.num)
            rowNumRerender();
        return row;
    }

    rowSetBefore (TableRowElement r, Map obj, [bool silent = false]) {
        var row = rowCreate(obj);
        rowCreateBefore(r, row);
        if(!silent)
            execHooks(Data.hook_value);
        execHooks(GridList.hook_render);
        if(super.num)
            rowNumRerender();
        return row;
    }

    _rowForSendFind (type, row) {
        return rows_send[type].contains(row);
    }

    _rowForSendFindRemove (type, row) => rows_send[type].remove(row);

    rowChanged (row) {
        var result = _rowForSendFind('insert', row);
        if(!result) {
            result = _rowForSendFind('update', row);
            if(!result)
                rows_send['update'].add(row);
        }
        execHooks(Data.hook_value);
    }

    rowRemove (TableRowElement row, [bool show = false]) {
        super.rowRemove(row, show);
        var result = _rowForSendFindRemove('insert', row);
        if(!result) {
            _rowForSendFindRemove('update', row);
            rows_send['delete'].add(row);
        }
        execHooks(Data.hook_value);
        execHooks(GridList.hook_render);
        if(super.num)
            rowNumRerender();
        return this;
    }

    checkRowValue (String key, dynamic value) {
        for (int i = 0, l = tbody.dom.childNodes.length; i < l; i++)
            if(getRowMap(tbody.dom.childNodes[i])[key] == value)
                return true;
        return false;
    }

    rowNumRerender() {
        if(drag) {
            for (int i = 0, l = tbody.dom.childNodes.length; i < l; i++)
                _setCell(tbody.dom.childNodes[i], 'position', i + 1);
        } else
            super.rowNumRerender();
    }

    _rowSwap(int n1, int n2) {
        if(n1 == n2)
            return;
        int n = math.max(super._rowSwap(n1, n2), 0);
        for (var i = n, l = tbody.dom.childNodes.length; i < l; i++)
            rowChanged(tbody.dom.childNodes[i]);
    }

    empty () {
        super.empty();
        _initSendRows();
        return this;
    }
}

abstract class Sumator<E> {

    add(E object);

    nullify();

    get total;
}

class Selector {
    static const int SELECTION_START = 0;
    static const int SELECTION_END = 1;
    List selection = new List();
    GridColumn gc;
    int pos;
    CJSElement label;
    Sumator sum;

    Selector (this.sum);

    startSelection (CJSElement el, MouseEvent e) {
        e.stopPropagation();
        pos = el.dom.cellIndex;
        if(label != null)
            label.hide();
        if(e.ctrlKey) {
            if(el.existClass('highlighted'))
                el.removeClass('highlighted');
            else
                el.addClass('highlighted');
        } else if(e.shiftKey) {
            moveSelection(el);
        } else {
            clearSelectionBorders();
            setSelection(el, SELECTION_START);
            setSelection(el, SELECTION_END);
            getCells().forEach((td) {
                var elem = new CJSElement(td);
                elem.addAction((e) => moveSelection(elem), 'mouseover');
            });
        }
    }

    stopSelection ([e]) {
        getCells().forEach((td) {
            new CJSElement(td).removeAction('mouseover');
        });
    }

    moveSelection (el) {
        setSelection(el, SELECTION_END);
    }

    setSelection (CJSElement element, position) {
        selection[position] = getCellPos(element.dom);
        applySelectionHighlight();
    }

    getCellPos ([TableCellElement element]) {
        if (element != null) {
            var parent = element.parent;
            return {
                'col': (pos != null)? pos : element.cellIndex,
                'row': parent.rowIndex
            };
        }
        return {
            'col': gc.cell_index,
            'row': -1
        };
    }

    getSelectionRect () {
        return new math.Rectangle(
            math.min(selection[SELECTION_START]['col'], selection[SELECTION_END]['col']),
            math.min(selection[SELECTION_START]['row'], selection[SELECTION_END]['row']),
            math.max(selection[SELECTION_START]['col'], selection[SELECTION_END]['col']) + 1,
            math.max(selection[SELECTION_START]['row'], selection[SELECTION_END]['row']) + 1
        );
    }

    applySelectionHighlight () {
        clearSelectionHighlight();
        getCells(getSelectionRect()).forEach((td) {
            new CJSElement(td)
                .addClass('highlighted');
        });
    }

    clearSelectionHighlight () {
        getCells().forEach((td) {
            new CJSElement(td)
                .removeClass('highlighted');
        });
    }
    /*applySelectionBorders: function () {
        var allHighlighted = $tbl.find('.highlighted');
        allHighlighted.each(function (i, item) {
            var index = $(item).index();
            var b = $tbl.find("td.highlighted:last").addClass("autofill-cover");
            if (!$(item).prev().is('td.highlighted')) {
                $(item).addClass('left');
            }
            if (!$(item).next().is('td.highlighted')) {
                $(item).addClass('right');
            }
            if (!$(item).closest('tr').prev().find('td:nth-child(' + (index + 1) + ')').hasClass('highlighted')) {
                $(item).addClass('top');
            }
            if (!$(item).closest('tr').next().find('td:nth-child(' + (index + 1) + ')').hasClass('highlighted')) {
                $(item).addClass('bottom');
            }
        });
    }*/

    clearSelectionBorders () {
        getCells().forEach((td){
            new CJSElement(td).removeClass('top')
                .removeClass('bottom')
                .removeClass('left')
                .removeClass('right');
        });
    }

    clearAll ([e]) {
        selection = [getCellPos(), getCellPos()];
        clearSelectionHighlight();
        clearSelectionBorders();
        if(label != null)
            label.hide();
    }

    getCellsSelected () {
        var s = [];
        for(var i=0; i < gc.grid.tbody.dom.childNodes.length; i++) {
            var tr = gc.grid.tbody.dom.childNodes[i];
            if(tr.nodeName == 'TR') {
                var td = tr.cells[pos];
                if(new CJSElement(td).existClass('highlighted'))
                    s.add(td);
            }
        }
        return s;
    }

    getCells ([math.Rectangle selectionRect = null]) {
        List arr = new List();
        if(selectionRect != null) {
            for(var i=0; i < gc.grid.tbody.dom.childNodes.length; i++) {
                var tr = gc.grid.tbody.dom.childNodes[i];
                if(tr.rowIndex >= selectionRect.top && tr.rowIndex < selectionRect.height) {
                    for(var j=0; j < tr.childNodes.length; j++) {
                        var td = tr.childNodes[j];
                        if(td.cellIndex >= selectionRect.left && td.cellIndex < selectionRect.width) {
                            arr.add(td);
                        }
                    }
                }
            }
        } else {
            for(var i=0; i < gc.grid.tbody.dom.childNodes.length; i++) {
                var tr = gc.grid.tbody.dom.childNodes[i];
                for(var j=0; j < tr.childNodes.length; j++) {
                    var td = tr.childNodes[j];
                    if(td.cellIndex == gc.cell_index) {
                        arr.add(td);
                    }
                }
            }
        }
        return arr;
    }

    getLabel (List sel) {
        sum.nullify();
        sel.forEach((sel) {
            var obj = gc.grid.getRowMap(sel.parent);
            sum.add(obj[gc.key].object);
        });
        var last = sel[sel.length - 1];
        if(label == null) {
            label = new CJSElement(new SpanElement())
                .addClass('sum-label');
        }
        gc.grid.setStyle({'position':'relative'});
        label.appendTo(gc.grid);
        var el = new CJSElement(last),
            offset = el.getHeight(),
            pos_tbody = gc.grid.getRectangle(),
            pos_cell = el.getRectangle(),
            pos = {
                'top': pos_cell.top - pos_tbody.top,
                'left': pos_cell.left - pos_tbody.left,
            };
        label.setStyle({
            'display': 'block',
            'top': '${pos['top'] + offset}px',
            'left': '${pos['left']}px',
            'z-index': '1'
        })..dom.text = 'Σ = ${sum.total}';
    }

    init (gc) {
        this.gc = gc;
        selection = [getCellPos(), getCellPos()];
        getCells().forEach((td){
            var el = new CJSElement(td);
            el.addClass('hightlightable');
            el.addAction((e) => startSelection(el, e), 'mousedown')
            .addAction((e) {
                e.stopPropagation();
                //applySelectionBorders();
                stopSelection();
                    getLabel(getCellsSelected());
                }, 'mouseup');
        });
        gc.grid.addAction(clearAll, 'mousedown')
            .addAction(stopSelection, 'mouseup');
    }
}