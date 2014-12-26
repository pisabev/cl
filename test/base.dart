part of test;

class INTL {
	static Delete_warning() => 'message';
	static Save_and_close() => 'message';
	static Save() => 'message';
	static Refresh() => 'message';
	static Delete() => 'delete';
	static Print() => 'print';
	static Clean() => 'Clean';
	static Language() => 'Language';
	static Filter() => 'Filter';
}

abstract class ItemBase {
    cl_app.Application ap;

    static const String save_before = 'save_before';
    static const String save_after = 'save_after';
    static const String get_before = 'get_before';
    static const String get_after = 'get_after';
    static const String del_before = 'del_before';
    static const String del_after = 'del_after';

    int _id = 0;

    dynamic contr_get, contr_save, contr_del;

    Map data_send = new Map();
    dynamic data_response;
    cl_util.Observer observer;

    ItemBase (this.ap, [int id = 0]) {
        _id = id;
        observer = new cl_util.Observer();
    }

    setId (int id) {
        _id = id;
        return this;
    }

    getId() => _id;

    _setData ([data = null]) {
        data_response = data;
        return true;
    }

    get ([loading]) {
        if(_id != null && _id != 0) {
            if(observer.execHooks(get_before)) {
                data_send['id'] = _id;
                ap.serverCall(contr_get, data_send, loading)
                .then((data) {
                    if(_setData(data))
                        observer.execHooks(get_after);
                }).catchError(ap.warning);
            }
        }
    }
    del ([loading]) {
        if(_id != null && _id != 0) {
            if(observer.execHooks(del_before)) {
                data_send['id'] = _id;
                ap.serverCall(contr_del, data_send, loading)
                .then((data) {
                    if(_setData(data))
                        observer.execHooks(del_after);
                }).catchError(ap.warning);
            }
        }
    }

    save ([loading]) {
        if(observer.execHooks(save_before)) {
            data_send['id'] = _id;
            ap.serverCall(contr_save, data_send, loading)
            .then((data) {
                if(_setData(data))
                    observer.execHooks(save_after);
            }).catchError(ap.warning);
        }
    }

    addHook (scope, func, [first]) {
        this.observer.addHook(scope, func, first);
        return this;
    }

    removeHook (scope, func) {
        this.observer.removeHook(scope, func);
        return this;
    }
}

abstract class ItemBuilder extends ItemBase implements cl_app.Item {
    Map w;
    cl_app.WinApp wapi;
    String contr = '';

    Map html;
    cl_action.Menu menuBottom;
    List actions_bottom = new List();
    cl_form.Form form;
    cl_gui.Tab tab;

    bool __close_set = false;
    bool __answer = false;
    var dom_inner, dom_bottom;

    ItemBuilder(ap, [id = 0]) : super (ap, id) {
        prepareControllers();
        winApi();
        initUI();
        setActionsBottom();
        initHTML(new cl.ContainerData(), new cl.ContainerOption());
        initWin();
        setHooks();
        setUI();
        if(id > 0)
            get();
        else
            setDefaults();
    }

    ItemBuilder.bound(ap, [id = 0]) : super (ap, id);

    setUI();

    setDefaults();

    prepareControllers() {
        contr_get = contr_get.reverse([]);
        contr_save = contr_save.reverse([]);
        if(contr_del != null)
            contr_del = contr_del.reverse([]);
    }

    setData () {
        if(data_response != null)
            set(data_response);
        return true;
    }

    winApi () {
        wapi = new cl_app.WinApp(ap);
        w['title'] = w['title'](_id);
        wapi.load(w, this);
    }

    initHTML (inner, bottom) {
        menuBottom = new cl_action.Menu(bottom);
        actions_bottom.forEach((action) => menuBottom.add(action));
        inner.append(getDom());
        dom_inner = inner;
        dom_bottom = bottom;
    }

    initWin() {
        wapi.win.getContent().addHookLayout(tab)
            ..addRow(dom_inner)
            ..addRow(dom_bottom);
        wapi.render();
    }

    setHooks () {
        addHook(ItemBase.get_after, readData);
        addHook(ItemBase.get_after, () => setBottomState(false));
        addHook(ItemBase.get_after, () {form.clear(); tab.tabsClear(); return true;});
        addHook(ItemBase.get_after, setData);
        addHook(ItemBase.save_before, checkData);
        addHook(ItemBase.save_before, sendData);
        addHook(ItemBase.save_before, () => setBottomState(false));
        addHook(ItemBase.save_after, readData);
        addHook(ItemBase.save_after, close);
        addHook(ItemBase.save_after, () {form.clear(); tab.tabsClear(); return true;});
        addHook(ItemBase.save_after, () {get(); return true;});
        addHook(ItemBase.del_before, ask);
        addHook(ItemBase.del_after, () {__close_set = true; close(); return true;});
    }

    get ([loading]) => super.get(loading != null? loading : dom_inner);

    ask ([message]) {
        if(__answer) {
            __answer = false;
            return true;
        }
        new cl_app.Questioner(ap)
            ..message = (message != null)? message : INTL.Delete_warning()
            ..onYes = () {__answer = true; del(); return true;}
            ..render();
        return false;
    }

    initUI () {
        form = new cl_form.Form();
        tab = new cl_gui.Tab();
    }

    set (data) {
        form.setData(data);
        return this;
    }

    hide () {
        tab.hide();
        return this;
    }

    show () {
        tab.show();
        return this;
    }

    createTab  (id, [name, obj]) {
        obj = (obj != null)? obj : new cl_form.GridForm(form);
        obj.addHook(cl_form.Data.hook_value, () => setBottomState(true))
        .addHook(cl_form.Data.hook_value, () => tab.tabChanged())
        .addHook(cl_form.Data.hook_require, () {tab.activeTab(id); return false; });
        tab.addTab(id, name, obj);
        tab.fillParent();
        //wapi.initLayout();
        return obj;
    }

    activeTab (id) => tab.activeTab(id);

    getDom () => tab.dom;

    checkData () {
        var req = form.getRequired();
        if (req.length > 0) {
            req.first.focus();
            return false;
        }
        return true;
    }

    sendData () {
        data_send = {'id': _id, 'data': form.toOBJ(true)};
        return true;
    }

    setActionsBottom () {
        actions_bottom = [
            new cl_action.Button().setName('save_true').setState(false).setTitle(INTL.Save_and_close()).setIcon('save').addAction((e) => saveIt(true)),
            new cl_action.Button().setName('save').setState(false).setTitle(INTL.Save()).setIcon('save').addAction((e) => saveIt(false)),
            new cl_action.Button().setName('clear').setState(false).setTitle(INTL.Refresh()).setIcon('change').addAction((e) => get(''))
        ];
        if(contr_del != null)
            actions_bottom.add(new cl_action.Button().setName('del').setState(false).setTitle(INTL.Delete()).setStyle({'float':'right'}).setIcon('delete').addAction((e) => del('')));
    }

    setBottomState (bool way) {
        actions_bottom.forEach((but) => but.setState(way));
        actions_bottom[actions_bottom.length-1].setState(_id > 0? true : false);
        return true;
    }

    saveIt (way) {
        __close_set = way;
        save();
    }

    close () {
        if(__close_set)
            closeWin();
        return true;
    }

    closeWin () => wapi.close();

    readData () {
        if(data_response != null && data_response['id'] != null)
            setId(data_response['id']);
        return true;
    }
}

abstract class Listing implements cl_app.Item {
    static const String MODE_LIST = 'list';
    static const String MODE_CHOOSE = 'choose';

    static const String get_before = 'get_before';
    static const String get_after = 'get_after';
    static const String del_before = 'del_before';
    static const String del_after = 'del_after';
    static const String print_before = 'print_before';

    dynamic lang_select;

    dynamic contr_get, contr_del, contr_print, contr_pdf;

    cl_app.Application ap;
    Map w;
    cl_app.WinApp wapi;
    Map html;
    cl_form.Form form;
    cl_action.Menu menu;
    cl_form.GridList grid;
    cl_util.Observer observer;
    Map params;
    dynamic data_response;
    cl_form.Check m_check;
    List chks = new List();
    List chks_set = new List();
    cl_form.Paginator paginator;

    bool __answer = false;
    Map _chk_to_row = new Map();

    String mode, key;

    Listing(this.ap, [bool noautoload = false]) {
        contr_get = contr_get.reverse([]);
        if(contr_del != null)
            contr_del = contr_del.reverse([]);
        wapi = new cl_app.WinApp(ap);
        wapi.load(w, this);
        //wapi.addCloseHook(() {this.getData = function(){}; return true;}.bind(this));
        observer = new cl_util.Observer();
        form = new cl_form.Form();
        initHTML();
        initMenu();
        setPaginator();
        initHooks();
        initAction();
        initTable();
        addHook(del_before, () => ask());
        addHook(del_after, getData);
        wapi.render();
        if(!noautoload)
            getData();
    }

    initAction(){}

    initHTML () {
        html = {'top':new cl.ContainerOption('ui-option-top'),
            'inner':new cl.ContainerData(),
            'bottom':new cl.ContainerOption('ui-option-bottom')};
        html['body_right'] = wapi.win.getContent()
            ..addRow(html['top'])
            ..addRow(html['inner'])
            ..addRow(html['bottom']);
    }

    initMenu () {
        menu = new cl_action.Menu(html['top']);
        if(mode == 'list') {
            menu.add(new cl_action.Button().setState(false).setName('del').setTitle(INTL.Delete()).setIcon('delete').addAction(delData));
            if(contr_print != null) {
                var p = new cl_action.ButtonOption().setState(false).setName('print').setTitle(INTL.Print()).setIcon('printer').addAction(printData);
                if(contr_pdf != null)
                    p.addSub(new cl_action.Button().setTitle('PDF').setIcon('page-white-acrobat').addAction(pdfData));
                menu.add(p);
            }
        }
    }

    setPaginator () {
        paginator = new cl_form.Paginator();
        paginator.addHook(cl_form.Data.hook_value, getData);
        html['bottom'].append(paginator);
    }

    validateEnter (e) {
        if(e.keyCode == 13)
            filterGet(e);
    }

    filterActive() {
        menu.setState('filter', true);
        menu.setState('clear', true);
    }

    initTable () {
        grid = new cl_form.GridListFixed();
        var h = new List();
        if(mode == MODE_LIST) {
            m_check = new cl_form.Check().setValue(1).setChecked(false).addAction(checkAll).setStyle({'margin':'5px'});
            h.add(new cl_form.GridColumn('check')..title = m_check..width = '1%');
        }
        initHeader().forEach((Map hrow) {
            var gc = new cl_form.GridColumn(hrow['key']);
            if(hrow.containsKey('title'))
                gc.title = hrow['title'];
            if(hrow.containsKey('sortable'))
                gc.sortable = hrow['sortable'];
            if(hrow.containsKey('width'))
                gc.width = hrow['width'];
            if(hrow.containsKey('filter')) {
                gc.filter = hrow['filter'];
                form.add(gc.filter);
                if (gc.filter is List) {
                    gc.filter.forEach((el_inner) {
                        el_inner.addHook(cl_form.Data.hook_value, filterActive);
                        if (el_inner is cl_form.Input)
                            el_inner.addAction(validateEnter, 'keyup');
                    });
                } else {
                    gc.filter.addHook(cl_form.Data.hook_value, filterActive);
                    if (gc.filter is cl_form.Input)
                        gc.filter.addAction(validateEnter, 'keyup');
                }
            }
            h.add(gc);
        });
        h.add(new cl_form.GridColumn('edit')..width = '1%');

        var filter = new cl_action.ButtonOption().setName('filter').setState(false).setTitle(INTL.Filter()).setIcon('filter').addAction(filterGet),
        clear = new cl_action.Button().setName('clear').setTitle(INTL.Clean()).setIcon('clear').addAction(filterClear),
        refresh = new cl_action.Button().setName('refresh').setTitle(INTL.Refresh()).setIcon('change').addAction(filterGet);
        filter.addSub(clear);
        menu.add(filter);
        menu.add(refresh);

        grid.initGridHeader(h)
        .addHook(cl_form.GridList.hook_row, customRow)
        .addHook(cl_form.GridList.hook_row, initRow);

        var cont = new cl.CJSElement(new DivElement())
        .setStyle({'overflow':'auto', 'height': '100%'})
        .append(grid);

        var order = initOrder();
        if(order != null && order.length == 2)
            grid.setOrder(order[0], order[1]);

        grid.addHook(cl_form.GridList.hook_order, getData);
        wapi.addLayoutHook(() => grid.observer.execHooks(cl_form.GridList.hook_layout));

        html['inner'].setStyle({'overflow':'hidden'}).append(cont);
    }

    initHeader ();

    onEdit(int id);

    customRow (arr) {
        var id = arr[1][key];
        arr[1]['edit'] = new cl_action.Button().setIcon('row-open').setStyle({'margin':'0px'}).addAction((e) => onEdit(id));
        return arr;
    }

    filterClear (e) {
        form.clear();
        menu.setState('clear', false);
    }

    filterGet (e) {
        paginator.setPage(1, true);
        getData();
    }

    setParamsGet () {
        params = {
            'order': grid.order,
            'paginator': paginator.getValue(),
            'filter': form.toOBJ()
        };
        return true;
    }

    setParamsDel () {
        params = {'ids': chks_set};
        return true;
    }

    initHooks () {
        addHook(get_before, setParamsGet);
        addHook(get_after, setData);
        addHook(del_before, setParamsDel);
        addHook(del_after, checkClean);
        addHook(print_before, setParamsDel);
    }

    ask ([message]) {
        if(__answer) {
            __answer = false;
            return true;
        }
        new cl_app.Questioner(ap)
            ..message = (message != null)? message : INTL.Delete_warning()
            ..onYes = () {__answer = true; delData(); return true;}
            ..render();
        return false;
    }

    initRow (arr) {
        var chk = new cl_form.Check().setName(arr[1][key]).setStyle({'margin':'5px'});
        chk.addAction((e) => check(chk, e), 'mousedown');
        chk.addAction((e) => e.stopPropagation(), 'click');
        chk.addAction((e) => e.preventDefault(), 'click');
        _chk_to_row[chk.hashCode] = arr[0];
        if (mode == MODE_CHOOSE)
            arr[0].onClick.listen((e) => onClick(grid.rowToMap(arr[0])));
        else if(mode == MODE_LIST)
            arr[0].onClick.listen((e) => arr[1]['edit'].object.dom.click());
        chks.add(chk);
        arr[1]['check'] = chk;
        if(arr[1]['edit'] != null)
            arr[1]['edit'].addAction((e) => e.stopPropagation(), 'click');
        return arr;
    }

    initOrder() {
        return [];
    }

    actionSend (type, controller) {
        if(observer.execHooks(type + '_before')) {
            ap.serverCall(controller, params, html['inner'])
            .then((data) {
                if(_setData(data))
                    observer.execHooks(type + '_after');
            }).catchError(ap.warning);
        }
        else
            _setData();
    }

    delData ([e]) => actionSend('del', contr_del);

    printer(contr) {
        if(observer.execHooks(print_before)) {
            var c = new cl_app.Confirmer(ap)
                ..title = INTL.Language()
                ..type = 'language'
                ..onOk = () => window.location.href = contr.reverse([lang_select.getValue(), params['ids'].join(',')]).substring(1);
            c.container.setStyle({'padding':'10px'}).append(lang_select);
            c.render(width:200);
        }
    }

    printData ([e]) => printer(contr_print);

    pdfData ([e]) => printer(contr_pdf);

    getData () => actionSend('get', contr_get);

    _setData ([data = null]) {
        data_response = data;
        return true;
    }

    setData () {
        paginator.setValue(data_response['total'], true);
        var scroll = grid.scrollTop;
        grid.empty();
        if(data_response['result'] != null)
            grid.renderIt(data_response['result']);
        grid.scrollTop = scroll;
        return true;
    }

    addHook (scope,func, [first]) {
        observer.addHook(scope,func, first);
        return this;
    }

    removeHook (scope,func) {
        observer.removeHook(scope,func);
        return this;
    }

    checkClean () {
        chks = new List();
        chks_set = new List();
        m_check.setChecked(false);
        checkActivation(false);
        return true;
    }

    onClick(arr){}

    check (el,e) {
        if(el.isChecked())
            rowUncheck(el);
        else
            rowCheck(el);
        if(e is Event) {
            e.stopPropagation();
            if(e.shiftKey)
                checkRange(el);
        }
        setDel();
    }

    checkRange (el) {
        var range = false;
        var stop = false;
        chks.forEach((check) {
            if(!stop && (check == el || check.getValue() == 1)) {
                range = true;
                stop = true;
            } else if(stop && (check == el || check.getValue() == 1)) {
                range = false;
            }
            if(range)
                rowCheck(check);
        });
    }

    checkAll (e) {
        if(m_check.getValue() == 1)
            chks.forEach((check) => rowCheck(check));
        else
            chks.forEach((check) => rowUncheck(check));
        setDel();
    }

    setDel () {
        chks_set = new List();
        chks.forEach((check) {
            if(check.getValue() == 1)
                chks_set.add(check.getName());
        });
        checkActivation(chks_set.length > 0? true : false);
    }

    checkActivation (way) {
        menu.setState('del', way);
        menu.setState('print', way);
    }

    rowCheck (el) {
        new cl.CJSElement(_chk_to_row[el.hashCode]).addClass('selected');
        el.setChecked(true);
    }

    rowUncheck (el) {
        new cl.CJSElement(_chk_to_row[el.hashCode]).removeClass('selected');
        el.setChecked(false);
    }
}

abstract class Report implements cl_app.Item {
    static const String get_before = 'get_before';
    static const String get_after = 'get_after';

    dynamic contr_get, contr_print, contr_csv;

    cl_app.Application ap;
    Map w;
    cl_app.WinApp wapi;
    Map html;
    cl_form.Form form;
    cl_action.Menu menu, menu2, menu_bottom;
    cl_form.GridList grid;
    cl_util.Observer observer;
    Map params;
    dynamic data_response;

    Report(this.ap) {
        contr_get = contr_get.reverse([]);
        contr_print = contr_print.reverse([]);
        contr_csv = contr_csv.reverse([]);
        wapi = new cl_app.WinApp(ap);
        wapi.load(w, this);
        observer = new cl_util.Observer();
        form = new cl_form.Form();
        initHTML();
        initMenu();
        initMenu2();
        initMenuBottom();
        initHooks();
        initTable();
        initFooter();
        wapi.render();
    }

    initHTML () {
        html = {'top':new cl.ContainerOption('ui-option-top'),
            'top_bottom': new cl.ContainerOption('ui-option-top'),
            'inner':new cl.ContainerData(),
            'bottom':new cl.ContainerOption('ui-option-bottom')};
        html['body_right'] = wapi.win.getContent()
            ..addRow(html['top'])
            ..addRow(html['top_bottom'])
            ..addRow(html['inner'])
            ..addRow(html['bottom']);
    }

    initMenu () {
        menu = new cl_action.Menu(html['top']);
    }

    initMenu2 () {
        menu2 = new cl_action.Menu(html['top_bottom']);
    }

    addTop (text, object) {
        form.add(object);
        var compl = new ComplexField(object);
        compl.setTitle(text);
        menu.add(compl);
        return this;
    }

    addFilter (text, object) {
        form.add(object);
        var compl = new ComplexField(object);
        compl.setTitle(text);
        menu2.add(compl);
        return this;
    }

    initMenuBottom () {
        menu_bottom = new cl_action.Menu(html['bottom']);
        var p = new cl_action.ButtonOption().setState(false).setName('print').setTitle(INTL.Print()).setIcon('printer').addAction(printData);
        p.addSub(new cl_action.Button().setTitle('PDF').setIcon('page-white-acrobat').addAction(pdfData));
        p.addSub(new cl_action.Button().setTitle('CSV').setIcon('page-white-excel').addAction(csvData));
        menu_bottom.add(p);
    }

    printData (e) {
        //window.open(centryl.baseurl + this.contr_print + '?' + this.params.join('&'), '_blank').print();
    }

    csvData (e) {
        //window.location = centryl.baseurl + this.contr_csv + '?' + this.params.join('&');
    }

    pdfData (e) {
        //window.location = centryl.baseurl + this.contr_csv + '?' + this.params.join('&');
    }

    initTable () {
        grid = new cl_form.GridListFixed();
        var h = initHeader();
        h.forEach((el) {
            if(el['sortable'])
                el['order'] = true;
            if(el['filter'])
                form.add(el['filter']);
        });
        grid.initHeader(h).addRowHook(customRow).addRowHookAfter(customRowAfter);
        var cont = new cl.CJSElement(new DivElement())
            ..setStyle({'height':'100%', 'overflow':'auto'})
            ..append(grid);

        List order = initOrder();
        if(order != null && order.length == 2)
            grid.setOrder(order[0], order[1]);

        grid.addHook(cl_form.GridList.hook_order, getData);
        wapi.addLayoutHook(() => grid.observer.execHooks(cl_form.GridList.hook_layout));

        html['inner'].setStyle({'overflow':'hidden'}).append(cont);
        grid.hide();
    }

    initHeader ();
    initFooter ();
    setFooter (Map data);

    customRow (arr) => arr;

    customRowAfter (arr) => arr;

    filterGet () => getData();

    setParamsGet () {
        params = {
            'order': grid.order,
            'filter': form.toOBJ()
        };
        return true;
    }

    initHooks () {
        addHook(get_after, setData);
        addHook(get_before, setParamsGet);
    }

    initOrder () {
        return new List();
    }

    getData ([e]) {
        if(observer.execHooks(get_before)) {
            ap.serverCall(contr_get, params, html['inner'])
            .then((data) {
                if(_setData(data))
                    observer.execHooks(get_after);
            }).catchError(ap.warning);
        }
        else
            _setData();
    }


    _setData ([data = null]) {
        data_response = data;
        return true;
    }

    setData () {
        grid.empty();
        if(data_response['result'] == null || data_response['result'].length == 0) {
            grid.hide();
            return true;
        }
        menu_bottom['print'].setState(true);
        grid.show();
        grid.renderIt(data_response['result']);
        setFooter(data_response);
        return true;
    }

    addHook (scope,func, [first]) {
        observer.addHook(scope,func, first);
        return this;
    }
}

class SelectList extends cl_form.Select {
    cl_app.Application ap;
    static const String hook_render = 'hook_render';
    static const String hook_call = 'hook_call';
    static const String hook_value = 'hook_value';
    static const String hook_before = 'hook_before';

    var contr;
    Map param = new Map();
    dynamic first;
    List list;
    cl_util.Observer observer;
    bool isLoading = false;

    SelectList(this.ap, this.contr, this.first, [callback, callbackb, type]) : super(type) {
        observer = new cl_util.Observer();
        observer.addHook(hook_render, renderList);
        observer.addHook(hook_call, callback is Function? callback : () => true);
        observer.addHook(hook_before, callbackb is Function? callbackb : () => true);
    }

    setParam (param) {
        this.param = {'param': param};
        return this;
    }

    load ([contr]) {
        if(isLoading)
            return this;
        if(observer.execHooks(hook_before)) {
            isLoading = true;
            ap.serverCall(contr == null? this.contr : contr, param, this).then((data) {
                list = data;
                observer.execHooks(hook_render);
                observer.execHooks(hook_value);
                observer.execHooks(hook_call);
                isLoading = false;
            }).catchError(ap.warning);
        }
        return this;
    }

    renderList () {
        cleanOptions();
        if(first is List && first.length == 2)
            addOption(first[0], first[1]);
        list.forEach((v) => addOption(v['k'], v['v']));
        return true;
    }

    setValue (value, [bool silent = false]) {
        if(value != null && getOptionsCount() == 0) {
            observer.removeHook(hook_value);
            observer.addHook(hook_value, () => setValue(value, silent));
            load();
        } else {
            super.setValue(value, silent);
        }
        return this;
    }
}

abstract class ItemOperation extends ItemBase implements cl_app.Item {
    static const String hook_value = 'hook_value';
    static const String save_before = 'save_before';
    static const String save_after = 'save_after';
    static const String get_before = 'get_before';
    static const String get_after = 'get_after';
    static const String del_before = 'del_before';
    static const String del_after = 'del_after';

    Map w;
    cl_app.WinApp wapi;
    Map html;
    List top_form_elements, menu_elements;
    cl_form.Form top_form;
    cl_action.Menu menu;
    cl_form.GridData grid;

    int top_height = 150;
    bool __close_set = false;

    ItemOperation(ap, [id = 0]) : super (ap, id) {
        contr_get = contr_get.reverse([]);
        contr_save = contr_save.reverse([]);
        contr_del = contr_del.reverse([]);
        wapi = new cl_app.WinApp(ap);
        wapi.load(w, this);
        initHTML();
        initInterface();
        topFormReset();
        setDefaultHooks();
        wapi.render();
        get();
    }

    initInterface () {
        topFormElements();
        menuElements();
        gridCreate();
        topCreate();
        setMenu();
    }

    initHTML () {
        html = {'right_options_top': new cl.ContainerOption('ui-option-top'),
            'right_inner': new cl.ContainerData(),
            'right_options_bottom': new cl.ContainerOption('ui-option-bottom')};
        html['body_right'] = wapi.win.getContent()
            ..addRow(html['right_options_top'])
            ..addRow(html['right_inner'])
            ..addRow(html['right_options_bottom']);

    }

    topFormElements ();

    menuElements();

    topCreate () {
        top_form = new cl_form.Form();

        getHook(tab, id) => () {tab.activeTab(id); return true; };

        var tab = new cl_gui.Tab().appendTo(html['right_options_top'].setHeight(top_height));
        html['right_options_top'].setStyle({'padding':'0px'});
        int i = 0;
        top_form_elements.forEach((page) {
            var div = new cl.CJSElement(new DivElement()).setClass('custom-order-tab');
            tab.addTab(i + 1, page['title'], div);

            int size = (100/page['data'].length).floor();
            int j = 0;
            page['data'].forEach((col) {
                var t = new cl_form.GridForm(top_form);
                t.addHook(cl_form.Data.hook_require, getHook(tab, i + 1));
                col.forEach((el) {
                    if(el.length > 1)
                        t.addRow(el);
                    else
                        top_form.add(el[0]);
                });
                size = (page['size'] is List)? page['size'][j] : size;
                t.setStyle({'width':size.toString() + '%', 'float':'left'}).appendTo(div);
                j++;
            });
            i++;
        });
        tab.activeTab(1);
        wapi.win.getContent().addHookLayout(tab);
    }

    setMenu () {
        menu = new cl_action.Menu(html['right_options_bottom']);
        menu_elements.forEach((el) => menu.add(el));
    }

    topFormReset () => top_form.clear();

    topFormSet (data) => top_form.setData(data);

    topFormDisable () => top_form.disable();

    gridCreate();

    onChange([bool way = true]);

    setWinTitle(id);

    onChangeAll () {
        menu.initButtons([]);
        return true;
    }

    drawRow (row) {
        grid.rowAdd(row);
        grid.show();
    }

    importRows (List rows) {
        rows.forEach((row) => grid.rowAdd(row));
        grid.show();
    }

    setDefaultHooks () {
        grid.addHook(hook_value, onChange);
        top_form.addHook(hook_value, onChange);
        addHook(get_after, setData);
        addHook(get_after, () {onChange(false); return true;});
        addHook(get_after, () {wapi.setTitle(setWinTitle(getId())); return true;});
        addHook(save_before, sendData);
        addHook(save_before, onChangeAll);
        addHook(save_after, close);
        addHook(save_after, afterSave);
        addHook(save_after, get);
    }

    checkData () {
        var req = top_form.getRequired();
        if (req.length > 0) {
            req.first.focus();
            return false;
        }
        return true;
    }

    sendData () {
        if(checkData()) {
            data_send = {
                'id': getId(),
                'data': {
                    'operation_top': top_form.toOBJ(),
                    'operation_rows': grid.getValue()
                }
            };
            return true;
        }
        return false;
    }

    setData () {
        topFormSet(data_response['operation_top']);
        grid.empty();
        grid.hide();
        if(data_response['operation_rows'] != null && data_response['operation_rows'].length > 0) {
            grid.setValue(data_response['operation_rows']);
            grid.show();
        }
        return true;
    }

    saveIt (way) {
        __close_set = way;
        save();
    }

    get([loading]) {
        if(!__close_set)
            super.get(loading);
        return true;
    }

    close () {
        if(__close_set)
            wapi.close();
        return true;
    }

    afterSave() {
        if(data_response != null && data_response.containsKey('id')) {
            setId(data_response['id']);
            return true;
        }
        return false;
    }
}

abstract class DashBoard implements cl_app.Item {
    cl_app.Application ap;
    cl_app.WinApp wapi;
    Map html;
    cl_form.Form form;
    cl_action.Menu apply;
    Map w;
    dynamic contr;

    DashBoard(this.ap) {
        contr = contr.reverse([]);
        wapi = new cl_app.WinApp(ap);
        wapi.load(w, this);
        html = {
            'top': new cl.ContainerOption('ui-option-top'),
            'inner':new cl.ContainerData()
        };
        wapi.win.getContent()
            ..addRow(html['top'])
            ..addRow(html['inner']);
    }

    getStats() => ap.serverCall(contr, form.toOBJ(), html['inner']).then(handleStatisticsResult).catchError(ap.warning);

    handleStatisticsResult(data);

}

class FileAttach extends cl_form.DataElement {
    List images;
    Map conts;
    cl_action.FileUploader uploader;
    cl.CJSElement container;
    String path_upload, path_tmp, path_media;

    FileAttach(this.container, uploader, this.path_upload, this.path_tmp, this.path_media) : super(uploader) {
        this.uploader = uploader;
        uploader.setUpload(path_upload);
        uploader.observer.addHook(cl_action.FileUploader.hook_loading, (file) {
            conts[file] = contentDraw();
            return true;
        });
        uploader.observer.addHook(cl_action.FileUploader.hook_loaded, (file) {
            var img = formValue(file);
            images.add(img);
            contentLoad(img, conts[file], images.length - 1, path_tmp);
            execHooks(cl_form.Data.hook_value);
            return true;
        });
    }

    contentDraw () {
        var cont = new cl.CJSElement(new DivElement()).setStyle({'position':'relative', 'padding-right':'20px', 'overflow':'hidden','float':'left'});
        var link = new cl.CJSElement(new AnchorElement()).setStyle({'line-height':'24px','display':'block'}).appendTo(cont);
        link.dom.target = '_blank';
        var img = new cl.CJSElement(new ImageElement()).setStyle({'vertical-align':'middle'}).appendTo(link);
        img.dom.src = 'packages/cjs/images/ui/loader.gif';
        var del = new cl.CJSElement(new AnchorElement()).setStyle({'position':'absolute','top':'0px','right':'0px','display':'block'})
        .setClass('i-tag-remove icon')
        .hide()
        .appendTo(cont);
        cont.addAction((e) => del.show(),'mouseover').addAction((e) => del.hide(),'mouseout');
        container.append(cont);
        return {
            'cont': cont,
            'link': link,
            'img': img,
            'del': del
        };
    }

    disable () {
        conts.forEach((k, cont) {
            cont['cont'].removeAction();
            cont['del'].remove();
        });
        remove();
    }

    contentLoad (img, cont, cur, path) {
        var ext = img['source'].split('.').removeLast().toLowerCase();
        var icon = 'page-white-put';
        switch(ext) {
            case 'jpg': icon = 'page-white-picture'; break;
            case 'jpeg': icon = 'page-white-picture'; break;
            case 'png': icon = 'page-white-picture'; break;
            case 'gif': icon = 'page-white-picture'; break;
            case 'xls': icon = 'page-white-excel'; break;
            case 'doc': icon = 'page-white-word'; break;
            case 'pdf': icon = 'page-white-acrobat'; break;
            case 'zip': icon = 'page-white-zip'; break;
            case 'rar': icon = 'page-white-zip'; break;
            case 'txt': icon = 'page-white-text'; break;
        }
        cont['img'].remove();
        cont['link'].addClass('$icon icon');
        cont['link'].dom.href = '$path/${img['source']}';
        cont['link'].dom.title = img['source'];
        cont['link'].dom.text = img['source'];
        cont['del'].addAction((e) => onDelete(img, cont, cur));
        conts[img['source']] = cont;
    }

    setValue (dynamic value, [bool silent = false]) {
        images = new List();
        conts = new Map();
        container.removeChilds();
        if(value is List) {
            value.forEach((img) {
                images.add(img);
                contentLoad(img, contentDraw(), images.length - 1, path_media);
            });
        }
        if (!silent)
            execHooks(cl_form.Data.hook_value);
        return this;
    }

    getValue () => images;

    onDelete (img, cont, cur) {
        if(img['opt'] == 1) {
            images.removeAt(cur);
        } else {
            img['opt'] = 3;
            execHooks(cl_form.Data.hook_value);
        }
        cont['cont'].remove();
    }

    formValue (source) => {'source': source,'opt': 1};
}

class ComplexField extends cl.CJSElement {
    cl.CJSElement domTitle;
    cl.CJSElement field;
    dynamic title;

    ComplexField (this.field) : super(new cl.CJSElement(new DivElement())..setClass('ui-field')) {
        domTitle = new cl.CJSElement(new SpanElement())..setClass('ui-field-title')..hide()..appendTo(dom);
        append(field);
    }

    setTitle (dynamic title) {
        this.title = title;
        domTitle
        .removeChilds()
        .append((title is String)? new Text(title) : title)
        .show();
        return this;
    }

    getTitle () {
        return this.title;
    }
}