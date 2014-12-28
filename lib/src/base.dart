part of base;

class CLElement<E extends Element> {

    E dom;
    Map _events 	= new Map<String, Map>();
    bool _state 	= true;
    static Expando exp = new Expando();

    CLElement(d) {
        dom = (d is CLElement)? d.dom : d;
        if(exp[dom] != null)
            _events = exp[dom];
        else
            exp[dom] = _events;
    }

    _execute(String type, Event event) {
        if(!_state)
            return false;
        List toExecute = new List();
        _events[type].forEach((k, v) => v.forEach(toExecute.add));
        toExecute.forEach((f) => f(event));
    }

    set state(state) => _state = state;

    get state => _state;

    setState(bool state) {
        _state = state;
        return this;
    }

    addAction(Function func, [String event_space = 'click']) {
        List ev = event_space.split('.');
        if(_events[ev[0]] == null)
            _events[ev[0]] = new Map<String, List>();

        var f = (e) => (_state)? func(e) : null;

        if (ev.length < 2) {
            var namespace = 0;
            while(_events[ev[0]]['space' + namespace.toString()] is List)
                namespace++;
            ev.add('space' + namespace.toString());
        }

        if(_events[ev[0]][ev[1]] == null)
            _events[ev[0]][ev[1]] = new List<Function>();

        dom.addEventListener(ev[0], f);
        _events[ev[0]][ev[1]].add(f);

        return this;
    }

    removeAction([String event_space = '']) {
        if(event_space.isNotEmpty) {
            List ev = event_space.split('.');
            if(_events[ev[0]] != null) {
                if(ev.length == 2 && _events[ev[0]][ev[1]] != null) {
                    _events[ev[0]][ev[1]].forEach((func) => dom.removeEventListener(ev[0], func));
                    _events[ev[0]].remove(ev[1]);
                    if (_events[ev[0]].isEmpty)
                        _events.remove([ev[0]]);
                } else {
                    _events[ev[0]].forEach((nsp, List data) {
                        data.forEach((func) => dom.removeEventListener(ev[0], func));
                    });
                    _events.remove(ev[0]);
                }
            }
        } else {
            removeActionsAll();
        }
        return this;
    }

    removeActionsAll() {
        _events.forEach((type, Map m) {
            m.forEach((nsp, List data) {
                data.forEach((func) => dom.removeEventListener(type, func));
            });
        });
        _events = new Map<String, Map>();
        exp[dom] = _events;
        return this;
    }

    getHeight() => dom.offsetHeight;

    getHeightInner() => dom.clientHeight - getHeightInnerShift();

    getHeightInnerShift() => _calcStyle(['padding-top','padding-bottom']);

    getHeightOuterShift() => _calcStyle(['margin-top','margin-bottom']);

    getWidth() => dom.offsetWidth;

    getWidthInner() => dom.clientWidth - getWidthInnerShift();

    getWidthInnerShift() => _calcStyle(['padding-left','padding-right']);

    getWidthOuterShift() => _calcStyle(['margin-left','margin-right']);

    Rectangle getRectangle() => dom.getBoundingClientRect();

    Rectangle getMutableRectangle() {
        Rectangle rect = dom.getBoundingClientRect();
        return new math.MutableRectangle(rect.left, rect.top, rect.width, rect.height);
    }

    setRectangle(Rectangle rect) {
        setStyle({
            'top': '${rect.top}px',
            'left': '${rect.left}px',
            'width': '${rect.width}px',
            'height': '${rect.height}px'
        });
        return this;
    }

    int _calcStyle (List style) {
        int l = 0;
        style.forEach((st) {
            var style = dom.getComputedStyle().getPropertyValue(st).replaceAll('px', '');
            if(style != '')
                l += double.parse(style).ceil();
        });
        return l;
    }

    getStyle(String style) {
        return dom.getComputedStyle().getPropertyValue(style);
    }

    fillParent() {
        CLElement p = new CLElement(dom.parentNode);
        setHeight(p.getHeightInner());
        return this;
    }

    setHeight(int height, [String unit = 'px']) {
        dom.style.height = height.toString() + unit;
        return this;
    }

    setWidth(int width, [String unit = 'px']) {
        dom.style.width = width.toString() + unit;
        return this;
    }

    setStyle(Map styleMap) {
        styleMap.forEach((k,v) => (k == 'float')? addClass(v) : dom.style.setProperty(k, v));
        return this;
    }

    setClass (String clas) {
        dom.classes.clear();
        dom.classes.add(clas);
        return this;
    }

    removeClass (String clas) {
        dom.classes.remove(clas);
        return this;
    }

    addClass (String clas) {
        dom.classes.add(clas);
        return this;
    }

    existClass(String clas) {
        return dom.classes.contains(clas);
    }

    setAttribute(String attr, String value) {
        dom.setAttribute(attr, value);
        return this;
    }

    hide() {
        dom.style.display = 'none';
        return this;
    }

    show() {
        dom.style.display = 'block';
        return this;
    }

    remove() {
        dom.remove();
        return this;
    }

    removeChilds() {
        dom.childNodes.toList().forEach((c) => c.remove());
        return this;
    }

    removeChild(el) {
        el.remove();
        return this;
    }

    append (child) {
        if(child is CLElement)
            dom.append(child.dom);
        else
            dom.append(child);
        return this;
    }

    appendTo(parent) {
        if(parent is CLElement)
            parent.dom.append(dom);
        else
            parent.append(dom);
        return this;
    }

    setHtml(String html) {
        dom.innerHtml = html;
        return this;
    }

    setText(String text) {
        dom.text = text;
        return this;
    }

}

class Container extends CLElement<DivElement> {

	bool auto = false;

	List rows = [];
	List cols = [];

	Observer observer;

	Container () : super(new DivElement()) {
		observer = new Observer();
	}

	Container addHookLayout(CLElement element) {
		observer.addHook('hook_layout', element.fillParent);
		return this;
	}

	Container addCol(Container col) {
		append(col);
		cols.add(col);
		col.addClass('ui-column');
		return this;
  	}

	Container addRow(Container row) {
		append(row);
		rows.add(row);
		return this;
  	}

    Container addSlider () {
        var col = new Container();
        var prev, next, prev_width, next_width, res, box;

        var getPrevCol = (cur) {
            var c = null;
            for (var i = 0; i < cols.length; i++)
                if(cols[i] == cur)
                    c = cols[i-1];
            return c;
        },
        getNextCol = (cur) {
            var c = null;
            for (var i = 0; i < cols.length; i++)
                if(cols[i] == cur)
                    c = cols[i+1];
            return c;
        };

        var drag = new Drag(col, 'slider');
        drag
            ..start((MouseEvent e) {
                e.stopPropagation();
                prev = getPrevCol(col);
                next = getNextCol(col);
                prev_width = prev.getWidth();
                next_width = next.getWidth();
                res = new CLElement(new DivElement()).setClass('ui-slider-shadow');
                box = col.getRectangle();
                res.setRectangle(box);
                document.body.append(res.dom);
            })
            ..on((MouseEvent e) {
                var min_p = prev_width + drag.dx - 150;
                if(min_p < 0)
                    drag.dx -= min_p;
                var min_n = next_width - drag.dx - 150;
                if(min_n < 0)
                    drag.dx += min_n;
                res.setStyle({'left': '${box.left + drag.dx}px'});
            })
            ..end((MouseEvent e) {
                res.remove();
                prev.setWidth(prev_width + drag.dx);
                next.setWidth(next_width - drag.dx);
            });

        append(col);
        cols.add(col);
        col.setClass('ui-slider');
        return this;
    }

	_initRows () {
		if (rows.length > 0) {
			int s_height = getHeightInner();
			int height = 0;
			List cont_auto = [];
			rows.forEach((Container c) {
				if (!c.auto) {
					height += c.getHeight() + c.getHeightOuterShift();
					c.initLayout();
				} else {
					cont_auto.add(c);
				}
			});
			if (cont_auto.length > 0) {
				int part_height = ((s_height - height) / cont_auto.length).floor();
				cont_auto.forEach((Container c) {
					c.setHeight(part_height - c.getHeightOuterShift());
					c.initLayout();
				});
			}
		}
	}

	_initCols () {
		if (cols.length > 0) {
			int s_width = getWidthInner();
			int s_height = getHeightInner();
			int width = 0;
			List cont_auto = [];
            cols.forEach((Container c) {
				if (!c.auto) {
					width += c.getWidth() + c.getWidthOuterShift();
					c.setHeight(s_height);
					c.initLayout();
				} else {
					cont_auto.add(c);
				}
			});
			if (cont_auto.length > 0) {
				int part_width = ((s_width - width) / cont_auto.length).floor();
				cont_auto.forEach((Container c) {
					c.setWidth(part_width - c.getWidthOuterShift());
					c.setHeight(s_height);
					c.initLayout();
				});
			}
		}
	}

	Container initLayout () {
		_initCols();
		_initRows();
		observer.execHooks('hook_layout');
        return this;
	}
}

class ContainerOption extends Container {
    ContainerOption ([String clas]) : super() {
        setClass('ui-options');
        if(clas != null)
            addClass(clas);
    }
}

class ContainerData extends Container {
    ContainerData ([String clas]) : super() {
        setClass('ui-inner');
        if(clas != null)
            addClass(clas);
        auto = true;
    }
}

class ContainerDataLight extends Container {
    ContainerDataLight ([String clas]) : super() {
        setClass('ui-inner light');
        if(clas != null)
            addClass(clas);
        auto = true;
    }
}

class ElementCollection {

    List indexOfElements = new List();

    add (dynamic el) {
        if (el is List)
            indexOfElements.addAll(el);
        else
            indexOfElements.add(el);
        return this;
    }

    remove (String name) {
        var el = null;
        indexOfElements.removeWhere((e) {
            if(e.getName() == name) {
                el = e;
                return true;
            }
            return false;
        });
        return el;
    }

    getElement (String name) => indexOfElements.firstWhere((el) => el.getName() == name, orElse: () => null);

    setState (String name, bool state) {
        for (var i=0, l=indexOfElements.length;i<l;i++)
            if (name.isNotEmpty) {
                if (indexOfElements[i].getName() == name)
                    indexOfElements[i].setState(state);
            }
            else
                indexOfElements[i].setState(state);
    }

    operator [](String key) => getElement(key);

    addHook (hook, func) {
        indexOfElements.forEach((el) => el.addHook(hook, func));
        return this;
    }
}

class LoadElement extends CLElement {
    CLElement container;

	LoadElement (this.container) : super(new DivElement()) {
		container.setStyle({'position':'relative'});
        setClass('ui-loader').appendTo(container);
        new Timer(new Duration(milliseconds: 10), () => addClass('active'));
    }

}