part of app;

class Application {

    Map data;
    Function data_persist = (Map data) => new Future.value(null);

    List<Notificator> listeners = new List();

	Element container;

	Notify notify;
	List<String> notifications = new List();

	Container
        page,

        fieldCenter,
        fieldBottom,

        desktop,
        gadgets,

        menu,
        addons,
        tabs;

	WinManager winmanager;
	ResourceManager resourcemanager;
	IconManager iconmanager;

    StartMenu start_menu;

	var system, count;

    Function server_call;

    Map stats_gadget = new Map();

	Application([Container cont]) {
		container = (cont != null)? cont : document.body;
		_createHtml();

		winmanager = new WinManager(this);
    	resourcemanager = new ResourceManager();
        iconmanager = new IconManager(desktop);
		window.onResize.listen((e) => initLayout());
        window.onError.listen(_onError);
        //document.body.onContextMenu.listen((e) => e.preventDefault());
        initLayout();
	}

	_createHtml() {
  		page = new Container()..setClass('ui-page');
		fieldCenter = new Container()..setClass('ui-content');
		fieldCenter.auto = true;
		fieldBottom = new Container()..setClass('ui-footer');

		page.addRow(fieldCenter).addRow(fieldBottom);

		desktop = new Container()..setClass('ui-desktop');
		gadgets = new Container()..setClass('ui-gadgets');
		menu = new Container()..setClass('ui-start-menu');
		addons = new Container()..setClass('ui-bottom-addons');
		tabs = new Container()..setClass('ui-bottom-tabs');

  		fieldCenter
  			..append(desktop)
            ..append(gadgets);

        fieldBottom
            ..append(addons)
            ..append(menu)
            ..append(tabs);

        container.append(page.dom);

        var timer = new CLElement(new DivElement()).setClass('ui-addon ui-timer').appendTo(addons);
        var timer_func = ([_]) => timer.dom.innerHtml = new DateFormat('Hm', 'en_US').format(new DateTime.now());
        new Timer.periodic(new Duration(seconds:1), timer_func);
        timer_func();
        system = new CLElement(new AnchorElement()).setClass('ui-addon icon message').appendTo(addons);
		count = new SpanElement()..style.display = 'none';
		count.onClick.listen((e) {
			showNotify();
		});
		system.append(count);
		notify = new Notify();
		addons.append(notify);
	}

	showNotify() {
		notify.render(notifications);
	}

	addNotification(String note) {
		notifications.add(note);
		count
			..style.display = 'block'
			..text = '${notifications.length}';
	}

    initStartMenu(String title, [String icon]) {
        start_menu = new StartMenu(title, icon);
        menu.append(start_menu.button);
    }

	setMenu (List menu) {
        List m = new List();
        List d = new List();
        menu.forEach((i) {
            if(i.containsKey('scope'))
                if(!checkPermission(i['scope'], 'read'))
                    return;
            if(i['desktop'] != null && i['desktop'])
                d.add(i);
            m.add(i);
        });
        start_menu.setMenuLeft(m);
        iconmanager.set(d);
        iconmanager.drawIcons();
	}

	initLayout () {
		page.fillParent();
		page.initLayout();
		iconmanager.initIcons();
        winmanager.initWinLayouts();
		return this;
	}

	load (String namespace, Function call) {
        var obj = resourcemanager.get(namespace);
        if (obj != null) {
            if (obj.wapi != null)
                winmanager.refreshWinTabs(obj.wapi.win, WinManager.zIndexWin);
            return obj;
        }
        obj = call();
        resourcemanager.add(namespace, obj);
        return obj;
    }

    warning (dynamic o, [stack]) {
        if(o is Map) {
            new Messager(this)
                ..title = o['title']
                ..message = o['message']
                ..details = o['details']
                ..type = o['type']
                ..render();
        } else {
            new Messager(this)
                ..title = 'Error'
                ..message = o.toString()
                ..details = stack.toString()
                ..type = 'error'
                ..render();
        }
    }

    setData(String key, String value) {
        if(data['client']['settings'] == null)
            data['client']['settings'] = new Map();
        data['client']['settings'][key] = value;
    }

    getData(String key) => data['client']['settings'][key];

    checkPermission(String scope, String operation) {
        if(data == null)
            return false;
        if(data['client']['user_group_id'] == 1)
            return true;
        if(data['client']['permissions'][scope] == null)
            return false;
        if(data['client']['permissions'][scope][operation] == 0)
            return false;
        return true;
    }

    Future serverCall(String contr, Map data, [dynamic loading = null]) => server_call(contr, data, loading);

    onServerCall(List data) {
        var matches = listeners.where((n) => n.id == data[0]);
        matches.forEach((l) => l.add(data[1]));
    }

    addChartGadget(title, contr, params) => new ChartGadget(this, title, contr, params)..appendTo(gadgets)..render();

    addStats(key, title, contr, params) {
        if(!stats_gadget.containsKey(key))
            stats_gadget[key] = new StatsGadget(this, key)..appendTo(gadgets);
        stats_gadget[key].add(title, contr, params);
    }

    _onError(ErrorEvent e) {
    	//e.message;
        new CLElement(new SpanElement()).appendTo(system).dom.text = '!';
    }

}

class Notify extends CLElement {

	var inner = new CLElement(new DivElement());

	Notify() : super(new DivElement()) {
		addClass('ui-notify');
		append(inner);
		addAction((e) => e.stopPropagation(),'mousedown');
	}

	addRow(CLElement el) => inner.append(el);

	render(List data) {print('sdsd');
		inner.removeChilds();
		data.forEach(addRow);
		show();
		var down = null;
		down = document.onMouseDown.listen((e) {
			hide();
			down.cancel();
		});
	}
}

class Notificator {

    String id;

    StreamController contr = new StreamController.broadcast();

    Notificator(this.id);

    add(data) => contr.add(data);

    listen(onData) => contr.stream.listen(onData);

}

class WinApp {
    Application app;
    Map w;
    Win win;

    WinApp (this.app);

    load (Map data, Object obj, [int startZIndex]) {
		w = data;
        if(w['type'] == 'bound') {
			startZIndex = (startZIndex != null)? startZIndex : WinManager.zIndexBound;
            win = app.winmanager.loadBoundWin(w != null? w : this.w, startZIndex);
        } else {
			startZIndex = (startZIndex != null)? startZIndex : WinManager.zIndexWin;
            win = app.winmanager.loadWindow(w != null? w : this.w, startZIndex);
        }
        win.observer.addHook('close', () => clear(obj));
        return this;
    }

    addFocusHook (Function func) {
        win.observer.addHook('focus', func);
        return this;
    }

    addLayoutHook (Function func) {
        win.observer.addHook('layout', func);
        return this;
    }

    addCloseHook (Function func) {
        win.observer.addHook('close', func);
        return this;
    }

    setTitle (String title) {
        win.setTitle(title);
		app.winmanager._map[win.hashCode.toString()]['link'].dom.text = title;
    }

    render () {
        win.render(w['width'], w['height'], w['left'], w['top']);
        return this;
    }

    initLayout () {
        win.initLayout();
        return this;
    }

    close () {
        win.close();
    }

    clear (Item obj) {
        app.resourcemanager.remove(obj);
        return true;
    }

}

class ResourceManager {

    Map _cache = new Map();

    add (String key, dynamic value) {
        _cache[key] = value;
        return this;
    }

    dynamic get (String key) {
        return _cache[key];
    }

    void remove (dynamic value) {
		var key;
		_cache.forEach((k, v) {
			if (v == value)
				key = k;
		});
		if(key != null)
			_cache.remove(key);
    }

}

class Win {

	CLElement container;

	Container win;
	Container win_top;
	Container win_body;

	CLElement win_title;
	CLElement win_close;
	CLElement win_max;
	CLElement win_min;

	math.MutableRectangle body;
	math.MutableRectangle box;
	math.MutableRectangle box_h;

	bool _maximized 	= false;
	int _zIndex 		= 0;

	int _min_width		= 200;
	int _min_height		= 50;

	CLElement _resize_cont;
	Rectangle _resize_rect;
	Map _resize_contr;

	math.Point _win_res_pos;
    math.Point _win_diff;
    math.Point _win_bound_low;
    math.Point _win_bound_up;

	utils.Observer observer;

    List<utils.KeyAction> _key_actions = new List();

	Win (CLElement cont) {
		container = cont;
		_createHtml();
		_setWinActions();
		observer = new utils.Observer();
        win.dom.tabIndex = 0;
        observer.addHook('focus', win.dom.focus);
        win.addAction((e) => _key_actions.forEach((action) => action.run(e)), 'keydown');
	}

	_createHtml() {
		win = new Container()..setClass('ui-win');
		win_top = new Container()..setClass('title');
		win_body = new Container()..setClass('content');
		win_body.auto = true;

		win_title = new CLElement(new HeadingElement.h3());
		win_title.dom.text = 'Win';
		win_close = new CLElement(new AnchorElement())
					..setClass('ui-win-close')
					..addAction((MouseEvent e) => e.stopPropagation(), 'mousedown')
					..addAction((MouseEvent e) => close(), 'click');
		win_max = new CLElement(new AnchorElement())
					..setClass('ui-win-max')
					..addAction((MouseEvent e) => e.stopPropagation(), 'mousedown')
					..addAction((MouseEvent e) => maximize(), 'click');
		win_min = new CLElement(new AnchorElement())
					..setClass('ui-win-min')
					..addAction((MouseEvent e) => e.stopPropagation(), 'mousedown')
					..addAction((MouseEvent e) => minimize(), 'click');

		win_top
			..append(win_title)
			..append(win_close)
			..append(win_max)
			..append(win_min);

		win
			..addRow(win_top)
			..addRow(win_body);

		CLElement top_left = new CLElement(new DivElement())..setClass('ui-win-corner-top-left');
		CLElement top_right = new CLElement(new DivElement())..setClass('ui-win-corner-top-right');
		CLElement bottom_left = new CLElement(new DivElement())..setClass('ui-win-corner-bottom-left');
		CLElement bottom_right = new CLElement(new DivElement())..setClass('ui-win-corner-bottom-right');
		CLElement top = new CLElement(new DivElement())..setClass('ui-win-top');
		CLElement right = new CLElement(new DivElement())..setClass('ui-win-right');
		CLElement bottom = new CLElement(new DivElement())..setClass('ui-win-bottom');
		CLElement left = new CLElement(new DivElement())..setClass('ui-win-left');

		_resize_cont = new CLElement(new DivElement())..setClass('ui-win-resize');
		_resize_contr = <String, CLElement> {
			't_c': top.appendTo(win),
			'r_c': right.appendTo(win),
			'b_c': bottom.appendTo(win),
			'l_c': left.appendTo(win),
			't_l_c': top_left.appendTo(win),
			't_r_c': top_right.appendTo(win),
			'b_l_c': bottom_left.appendTo(win),
			'b_r_c': bottom_right.appendTo(win)
		};
	}

	_setWinActions() {
		new utils.Drag(win_top, 'stop')
			..start((MouseEvent e) {
                body = container.getMutableRectangle();
                _initSize();
				win.addClass('transform');
                Point page = new Point(e.page.x, e.page.y);
                _win_diff = page - box.topLeft;
			})
			..on((MouseEvent e) {
                e.stopPropagation();
                Point pos = new Point(e.page.x, e.page.y) - _win_diff;
                pos = utils.boundPoint(pos, _win_bound_low, _win_bound_up);
				setPosition(pos.x, pos.y);
			})
			..end((e) => win.removeClass('transform'));

		var N = new utils.Drag(_resize_contr['t_c'], 'stop')
			..start((e) => _winResizeBefore(e))
			..on((e) => _winResizeOn('N', e))
			..end(_winResizeAfter);
        var E = new utils.Drag(_resize_contr['r_c'], 'stop')
			..start((e) => _winResizeBefore(e))
			..on((e) => _winResizeOn('E', e))
			..end(_winResizeAfter);
		var S = new utils.Drag(_resize_contr['b_c'], 'stop')
			..start((e) => _winResizeBefore(e))
			..on((e) => _winResizeOn('S', e))
			..end(_winResizeAfter);
		var W = new utils.Drag(_resize_contr['l_c'], 'stop')
			..start((e) => _winResizeBefore(e))
			..on((e) => _winResizeOn('W', e))
			..end(_winResizeAfter);
		var NW = new utils.Drag(_resize_contr['t_l_c'], 'stop')
			..start((e) => _winResizeBefore(e))
			..on((e) => _winResizeOn('NW', e))
			..end(_winResizeAfter);
		var NE = new utils.Drag(_resize_contr['t_r_c'], 'stop')
			..start((e) => _winResizeBefore(e))
			..on((e) => _winResizeOn('NE', e))
			..end(_winResizeAfter);
		var SW = new utils.Drag(_resize_contr['b_l_c'], 'stop')
			..start((e) => _winResizeBefore(e))
			..on((e) => _winResizeOn('SW', e))
			..end(_winResizeAfter);
		var SE = new utils.Drag(_resize_contr['b_r_c'], 'stop')
			..start((e) => _winResizeBefore(e))
			..on((e) => _winResizeOn('SE', e))
			..end(_winResizeAfter);
	}

	_winResizeBefore(MouseEvent e) {
		e.stopPropagation();
		_win_res_pos = new math.Point(e.page.x, e.page.y);
		win.addClass('transform');
		container.append(_resize_cont);
	}

	_winResizeOn(String destination, MouseEvent e) {
		e.stopPropagation();
		math.Point pos = new math.Point(e.page.x, e.page.y);
		//pos = pos.bound(new utils.Point(body.p.x, body.p.y), new utils.Point(body.p.x + body.w - 10, body.p.y + body.h - 10));
		math.Point diff_pos = _win_res_pos - pos;

		Function calc = (int dim, [String type = 'width']) {
			return (type == 'width')? math.max(dim, _min_width) : math.max(dim, _min_height);
		};

		math.MutableRectangle p = new math.MutableRectangle(box.left, box.top, box.width, box.height);

		switch(destination) {
			case 'N':
				p.height = calc(p.height + diff_pos.y, 'height');
				p.top = p.top + (box.height - p.height);
				break;
			case 'E':
				p.width = calc(p.width - diff_pos.x);
				break;
			case 'S':
				p.height = calc(p.height - diff_pos.y, 'height');
				break;
			case 'W':
				p.width = calc(p.width + diff_pos.x);
				p.left = p.left + (box.width - p.width);
				break;
			case 'SE':
				p.width = calc(p.width - diff_pos.x);
				p.height = calc(p.height - diff_pos.y, 'height');
				break;
			case 'SW':
				p.width = calc(p.width + diff_pos.x);
				p.height = calc(p.height - diff_pos.y, 'height');
				p.left = p.left + (box.width - p.width);
				break;
			case 'NW':
				p.width = calc(p.width + diff_pos.x);
				p.height = calc(p.height + diff_pos.y, 'height');
				p.left = p.left + (box.width - p.width);
				p.top = p.top + (box.height - p.height);
				break;
			case 'NE':
				p.width = calc(p.width - diff_pos.x);
				p.height = calc(p.height + diff_pos.y, 'height');
				p.top = p.top + (box.height - p.height);
				break;
		}

		_resize_cont
			..setWidth(p.width)
			..setHeight(p.height)
			..setStyle({'left': '${p.left}px', 'top': '${p.top}px'});
		_resize_rect = p;
	}

	_winResizeAfter(e) {
		_resize_cont.remove();
		if(_resize_rect != null) {
			setSize(_resize_rect.width, _resize_rect.height);
			setPosition(_resize_rect.left, _resize_rect.top);
			initLayout();
            _resize_rect = null;
		}
		win.removeClass('transform');
	}

	setTitle(dynamic title) {
        win_title.removeChilds();
		if(title is CLElement) {
			win_title.append(title);
		} else {
			win_title.dom.text = title;
		}
		return this;
	}

	setIcon(String icon) {
		win_title.setClass(icon + ' icon');
		return this;
	}

	setZIndex(int zIndx) {
		_zIndex = zIndx;
		win.setStyle({'z-index': zIndx.toString()});
		return this;
	}

	maximize() {
        body = container.getMutableRectangle();
		if(_maximized == true) {
			win.addClass('ui-win-shadowed');
			win_top.state = true;
            if(box_h.width == 0 && box_h.height == 0) {
                box_h.width = box.width - 100;
                box_h.height = box.height - 100;
                box_h.left = 50;
                box_h.top = 50;
            }
			setSize(box_h.width, box_h.height);
			setPosition(box_h.left, box_h.top);
			_maximized = false;
			_resize_contr.forEach((k, v) => v.show());
			initLayout();
		} else {
			win.removeClass('ui-win-shadowed');
			box_h = new math.MutableRectangle(box.left, box.top, box.width, box.height);
			setSize(body.width, body.height);
			_maximized = true;
			win_top.state = false;
			_resize_contr.forEach((k, v) => v.hide());
			initPosition(body.left, body.top);
			initLayout();
		}
		return this;
	}

	minimize() {
		if(observer.execHooks('minimize'))
			win.hide();
		return this;
	}

	render([int width = 0, int height = 0, int x = 0, int y = 0]) {
        body = container.getMutableRectangle();
        box = new math.MutableRectangle(0, 0, 0, 0);
		win.appendTo(container);
        width = width == null? null : math.min(body.width, width);
        height = height == null? null : math.min(body.height, height);
		if(((width == null || width == 0) && (height == null || height == 0)) || (width == body.width && height == body.height)) {
			maximize();
		} else {
            _setWidth(math.max(width,_min_width));
            _setHeight(height != null? math.max(height, _min_height) : math.min(win.getHeight(), container.getHeightInner()));
            _initSize();
            x = x != null? x : 0;
            y = y != null? y : 0;
            initPosition(x, y);
            initLayout();
            win.addClass('ui-win-shadowed');
		}
        observer.execHooks('focus');
		return this;
	}

	setPosition(int left, int top) {
        box.top = top;
        box.left = left;
        var m = {'top': '${top}px', 'left': '${left}px'};
        win.setStyle(m);
		_resize_cont.setStyle(m);
		return this;
	}

	setSize(int width, int height) {
        _setWidth(width);
        _setHeight(height);
		_initSize();
		return this;
	}

    _setWidth(int width) {
        box.width = width;
        int w = width - win.getWidthInnerShift();
        win.setWidth(w);
        _resize_contr['t_c'].setWidth(w);
        _resize_contr['b_c'].setWidth(w);
        _resize_cont.setWidth(width - _resize_cont.getWidthInnerShift());
    }

    _setHeight(int height) {
        box.height = height;
        int h = height - win.getHeightInnerShift();
        win.setHeight(h);
        _resize_contr['l_c'].setHeight(h);
        _resize_contr['r_c'].setHeight(h);
        _resize_cont.setHeight(height - _resize_cont.getHeightInnerShift());
    }

    _initSize() {
        _win_bound_low = body.topLeft;
        _win_bound_up = new math.Point(body.width - box.width, body.height - box.height);
    }

	initPosition([int x, int y]) {
		if(!_maximized) {
			box = utils.centerRect(box, body);
			if (x != 0 && y != 0)
				box = utils.boundRect(new Rectangle(x, y, box.width, box.height), body);
			setPosition(box.left, box.top);
		} else {
			setPosition(body.left, body.top);
		}
		return this;
	}

	initLayout() {
		win.initLayout();
		observer.execHooks('layout');
		return this;
	}

	Container getContent() {
		return win_body;
	}

	close() {
		if(observer.execHooks('close')) {
			_resize_cont.remove();
			win.remove();
		}
	}

    addKeyAction(utils.KeyAction action) => _key_actions.add(action);

}

class WinManager {
    Application app;
    String tab_clas = 'ui-win-tab';
    String tab_clas_active = 'ui-win-tab-active';
    List cache_wins = new List();
    List cache_wins_bound = new List();
    CLElement desk_cont;
    CLElement tabs_cont;
    static const int zIndexWin = 500;
    static const int zIndexBound = 900;
	Map _map = new Map();

	WinManager (Application app) {
        this.app = app;
        desk_cont = app.fieldCenter;
        tabs_cont = app.tabs;
    }

    loadWindow (o, [int startZIndex = zIndexWin]) {
        var win = new Win(desk_cont)..setTitle(o['title']);
        if(o['icon'] != null)
            win.setIcon(o['icon']);

        win.observer.addHook('close', () => removeWin(win, startZIndex));
        win.observer.addHook('minimize', () => _map[win.hashCode.toString()]['cont'].setClass(tab_clas));

        var tab = createTab(o['title'], o['icon']);
        tabs_cont.append(tab['cont']);

		_map[win.hashCode.toString()] = tab;
        cache_wins.add(win);

        win.win.addAction((e) => refreshWinTabs(win, startZIndex), 'mousedown');
        tab['link'].addAction((e) => refreshWinTabs(win, startZIndex), 'mousedown');
        refreshWinTabs(win, startZIndex);
        return win;
    }

    loadBoundWin (o, [int startZIndex = zIndexBound, e]) {
        if (!checkBoundWins()) {
            new UnactivePage(app, startZIndex - 1);
        }
        var win = new Win(desk_cont)
            ..setTitle(o['title']);
        if (o['icon'] != null)
            win.setIcon(o['icon']);

        cache_wins_bound.add(win);

        win.observer.addHook('close', () => removeBoundWin(win, startZIndex));
        win.win.addAction((e) => indexResolver(cache_wins_bound, startZIndex, win), 'mousedown');

        win.win_min.remove();
        win.win_max.remove();
        indexResolver(cache_wins_bound, startZIndex, win);
        return win;
    }

    Map createTab (String title, [String icon]) {
        var div = new CLElement(new DivElement()).setClass(this.tab_clas),
            span = new CLElement(new SpanElement()).appendTo(div),
            link = new CLElement(new AnchorElement()).appendTo(span);
		link.dom.text = title;
        if(icon != null)
            link.setClass(icon + ' icon');
        return {'cont':div, 'link':link};
    }

    refreshWinTabs (win, startZindex) {
        win = indexResolver(cache_wins, startZindex, win);
        if(win != null) {
            cache_wins.forEach((w) {
                if(w != win)
                    _map[w.hashCode.toString()]['cont'].setClass(tab_clas);
            });
            win.win.show();
			_map[win.hashCode.toString()]['cont'].setClass(tab_clas_active);
        }
    }

    checkBoundWins () {
        return (cache_wins_bound.length > 0)? true : false;
    }

    removeWin (win, startZIndex) {
		_map[win.hashCode.toString()]['cont'].remove();
        clearCache(cache_wins, win);
        refreshWinTabs(null, startZIndex);
        return true;
    }

    removeBoundWin (win, startZIndex) {
        clearCache(cache_wins_bound, win);
        indexResolver(cache_wins_bound, startZIndex);
        if (!checkBoundWins())
            new UnactivePage(app);
        return true;
    }

    clearCache (List cache, win) {
		cache.removeWhere((w) => w == win);
    }

    indexResolver (cache, startZIndex, [win]) {
        List sorter = [];
        Map map = {};
        if(win != null)
            win.setZIndex(startZIndex + cache.length + 1);
        cache.forEach((w) {
            sorter.add(w._zIndex);
            map[w._zIndex] = w;
        });
        sorter.sort();
        var start = startZIndex + 1;
		var i = 0;
        sorter.forEach((v) {
            map[v].setZIndex(start + i);
			i++;
        });
		if(sorter.length > 0) {
        	win = map[sorter.last];
        	if(win != null)
            	win.observer.execHooks('focus');
			return win;
		}
        return null;
    }

    initWinLayouts () {
        cache_wins.forEach((w) => w.initLayout());
    }

}

class IconManager {
    CLElement container;
    List icons = new List();

    IconManager (this.container);

    add (o) {
        var cont = new CLElement(new AnchorElement())
        .addAction((e) => o['action']());
        new CLElement(new DivElement())
        .setClass('${o['icon']} icon-big')
        .appendTo(cont);
        var h3 = new CLElement(new HeadingElement.h3())
        .appendTo(cont);
        cont.addClass('desktop-icon');
        h3.dom.text = o['title'];
        icons.add(cont);
    }
    set (List arr) {
        arr.forEach((o) => add(o));
        return this;
    }

    drawIcons () {
        initIcons(true);
    }

    initIcons ([bool render = false]) {
        if(icons.length == 0)
            return;
        var renderTo = container,
        height = renderTo.getHeight(),
        icon_height = 122,
        vert_count = (height/icon_height).floor(),
        left = 0,
        top = 0,
        i = 0;
        icons.forEach((icon) {
            if (i%vert_count==0 && i!=0) {
                left += 110;
                top = 0;
            }
            icon.setStyle({'top':top.toString() + 'px', 'left':left.toString() + 'px'});
            if (render)
                renderTo.append(icon);
            top += icon_height;
            i++;
        });
    }
}

class StartMenu extends CLElement {

    String title, icon;

    CLElement cont_top, cont_body, cont_left, cont_right, button;

    bool rendered = false;

    StartMenuElement menu;

	StartMenu ([String title = 'start', String icon = '']) : super (new DivElement()) {
		setClass('ui-start-menu-win');
        this.title = title;
        this.icon = icon;
        createDom();
        createButton();
    }

    createDom () {
        cont_top = new CLElement(new DivElement()).setClass('ui-start-menu-top')
            .appendTo(this)
            .addAction(_domClick,'click');
        cont_body = new CLElement(new DivElement())
            .setClass('ui-start-menu-body')
            .appendTo(this);
        cont_left = new CLElement(new DivElement())
            .setClass('ui-start-menu-left')
            .appendTo(cont_body)
            .addAction(_domClick,'click');
        cont_right = new CLElement(new DivElement())
            .setClass('ui-start-menu-right')
            .appendTo(cont_body)
            .addAction(_domClick,'click');
    }

    createButton () {
        button = new CLElement(new AnchorElement())
            .setClass('ui-start-menu-button')
            .setStyle({'background-image': 'url(${icon})'})
            .addAction(_onClick,'click');
        button.dom.text = title;
    }

    _domClick (e) {
        e.stopPropagation();
        menu.closeSub();
    }

    removeMenu ([e]) {
		menu.closeSub();
        remove();
        rendered = false;
        return this;
    }

    renderMenu () {
        var pos = button.getRectangle();
        document.body.append(this.dom);
        var count = menu.childs.length;
        var height = menu.childs[0].getHeight();
        cont_body.setHeight(count*height + 50);
        setStyle({'top':'${pos.top - getHeight()}px', 'left':'${pos.left}px'});
        var doc = new CLElement(document);
		doc.addAction((e) {
            removeMenu();
            doc.removeAction('click.start');
        }, 'click.start');
        rendered = true;
        return this;
    }

    setMenuLeft (arr) {
        Map map = new Map();
        menu = new StartMenuElement();
        arr.forEach((obj) {
            var o = {
                'title': obj['title'],
                'icon': obj['icon_ref'] != null? obj['icon_ref'] : obj['icon'],
                'action': obj['action'],
                'ref': obj['ref'] != null? obj['ref'] : '',
                'key': obj['key'] != null? obj['key'] : '',
                'desktop': obj['desktop'],
                '_m': this
            };
            map[o['key']] = (o['ref'] == 'main')? menu.addChild(o) : map[o['ref']].addChild(o);
        });
        cleanMap(Map m) {
            String key;
            m.forEach((k, StartMenuElement v) {
                if(v.childs.length == 0 && v.action == null) {
                    v.parent.removeChild(v);
                    key = k;
                }
            });
            if(key != null) {
                m.remove(key);
                cleanMap(m);
            }
        };
        cleanMap(map);
        menu.childs.forEach((child) => cont_left.append(child));
        return this;
    }

    setMenuRight (List arr) {
        arr.forEach((obj) {
            var o = {
                'title': obj['title'],
                'icon': obj['icon'],
                'action': obj['action']
            };
            var b = new action.Button();
            b.domAction.addClass('type2');
            b.setTitle(o['title']);
            if(o['icon'] != null)
				b.setIcon(o['icon']);
            b.addAction((e) => o['action']());
            b.addAction(removeMenu);
            b.appendTo(cont_right);
        });
        return this;
    }

    setUser (String user) {
        var u = new CLElement(new SpanElement())
            .setClass('ui-app-user icon user')
            .appendTo(cont_top);
		u.dom.text = user;
    }

    _onClick (e) {
        e.stopPropagation();
        if(rendered)
            return removeMenu();
        else
            return renderMenu();
    }
}

class StartMenuElement extends CLElement {
    String title, icon;

    Function action;
    List childs = new List();

	StartMenuElement parent;

    CLElement cont;

	int level = 0;

	StartMenu _m;

    StartMenuElement([Map o]) : super(new SpanElement()) {
		setClass('ui-start-menu-element');
		if(o == null)
			return;
        title = o['title'];
        icon = o['icon'];
        action = (o['action'] is Function)? o['action'] : (){};
		_m = o['_m'];
        createDom();
    }

    createDom () {
		addAction(showSub, 'mouseover');
        var a = new CLElement(new AnchorElement())
            .addAction((e) => action(), 'click')
			.addAction((e) => _m.removeMenu(), 'click')
            .appendTo(this);
		if(icon != null)
			a.setClass(icon + ' icon');
		a.dom.innerHtml = title;
    }

    addChild (Map el) {
        var child = new StartMenuElement(el);
        child.level++;
        child.parent = this;
        childs.add(child);
        addClass('ui-start-menu-childs');
        return child;
    }

    removeChild(StartMenuElement el) {
        childs.remove(el);
        if(childs.length == 0)
            removeClass('ui-start-menu-childs');
    }

    selectParent () {
        var p = parent;
        while(p != null) {
            p.addClass('ui-start-menu-element-sel');
            p = p.parent;
        }
    }

    showSub (e) {
        if(parent != null)
            parent.closeSub();
        selectParent();
        if(childs.length == 0)
            return false;
        if (cont == null) {
            cont = new CLElement(new DivElement())
                .setClass('ui-start-menu-left-inner');
            var h = getHeight();
            var height = 0;
            childs.forEach((child) {
                height += h;
                cont.append(child);
            });
            var pos = getRectangle();
            cont.setStyle({'position':'absolute',
						'top': '${pos.top}px',
						'left': '${pos.left + 200}px',
						'height': '${height}px'});
        }
        document.body.append(cont.dom);
        _fixHeight();
    }

    _fixHeight() {
        var pos = getRectangle();
        var reach = pos.top + cont.getHeight();
        var diff = reach - new CLElement(document.body).getHeight();
        var top = pos.top;
        if (diff > 0)
            top -= diff;
        cont.setStyle({'position':'absolute', 'top': '${top}px'});
    }

    closeSub () {
        childs.forEach((child) {
            if(child.cont != null)
                child.cont.remove();
            child.removeClass('ui-start-menu-element-sel');
            child.closeSub();
        });
    }
}

class UnactivePage extends CLElement {

    UnactivePage (Application app, [int zIndex = 889]) : super(new DivElement()) {
        var el = document.getElementById('ui-unactivepage');
        if (el != null) {
            el.remove();
        } else {
            var container = new CLElement(app.container).setStyle({'position':'relative'});
            dom.id = 'ui-unactivepage';
            appendTo(app.container);
            setStyle({'z-index': zIndex.toString(),
                'width':container.getWidth().toString() + 'px',
                'height':container.getHeight().toString() + 'px'});
            new Timer(new Duration(milliseconds: 10), () => addClass('active'));
        }
    }

}

class Item {

	Map w = {'title': 'Window'};
	WinApp wapi;

}

class Hint extends CLElement {
    Function callBack;
    int time = 300;
    var timer_show, timer_close;
    CLElement hintDom;

    Hint () : super(new AnchorElement()) {
        setHtml('?');
        addAction(_startShow, 'mouseover');
        addAction(_stopShow, 'mouseout');
        addAction(_startClose, 'mouseout');

        hintDom = new CLElement(new DivElement())
        .setClass('ui-hint')
        .addAction(_stopClose, 'mouseover')
        .addAction(_startClose, 'mouseout');
    }

    setCallBack (Function callBack) {
        this.callBack = callBack;
        return this;
    }

    setData (data) {
        hintDom.setHtml(data);
        return this;
    }

    _startShow (e) {
        callBack();
        timer_show = new Timer(new Duration(milliseconds:time), () => showHint(e));
    }

    _stopShow  (e) => timer_show.cancel();

    _startClose (e) => timer_close = new Timer(new Duration(milliseconds:time), () => _closeHint());

    _stopClose (e) => timer_close.cancel();

    showHint (MouseEvent e) {
        var top = e.page.y - 10;
        var left = e.page.x + 20;
        if ((left + 220) > new CLElement(document.body).getWidth())
            left = e.page.x - 220;
        hintDom
        .setStyle({'top': '${top}px', 'left': '${left}px'})
        .appendTo(document.body);
    }

    _closeHint () => hintDom.remove();

}

class HintManager {
    Application ap;
    dynamic route;
    CLElement hint;
    String position;
    Map data = new Map();

    HintManager (this.ap, [String this.position]);

    setRoute (route) {
        this.route = route;
        return this;
    }

    set (title, key) {
        data[key] = new Map();
        data[key]['hint'] = new Hint();
        data[key]['data'] = null;
        data[key]['hint'].setCallBack(() => initData(key));
        var c = new CLElement(new DivElement()).setClass('ui-hint-spot');
        var t = new CLElement(new SpanElement())
        .setHtml(title)
        .appendTo(c);
        data[key]['hint'].appendTo(c);
        if(position == 'right' || position == 'left')
            c.setStyle({'float':position});
        return c;
    }

    initData (key) {
        if(data[key]['data'] != null)
            data[key]['hint'].setData(data[key]['data']);
        else {
            ap.serverCall(route.reverse([key]), {'locale': Intl.defaultLocale}, null).then((response) {
                if(response != null)
                    data[key]['data'] = response;
                data[key]['hint'].setData(data[key]['data']);
            });
        }
    }
}

class Messager {
    Application ap;
    String _type, _title, _message, _details;
    CLElement _mesDom;

    Messager (this.ap) {
        createDom();
    }

    createDom() => _mesDom = new ContainerDataLight();

    get container => _mesDom;

    set title(String title) => _title = title;

    set type(String type) => _type = type;

    set message(String message) => _message = message;

    set details(String details) => _details = details;

    render ({int width: 400, int height: null}) {
        Win win = ap.winmanager.loadBoundWin({
            'title': _title,
            'icon': (_type != null)? _type : 'attention'});
        if(_message != null)
            _mesDom.addClass('ui-message').setText(_message);
        if(_details != null)
            _mesDom.addClass('ui-message').append(new SpanElement()..className = 'details'..text = _details);
        win.getContent().addRow(_mesDom);
        win.render(width, height);
    }
}

class Questioner extends Messager {
    CLElement _yesDom, _noDom;
    Function _callback_yes = () => true, _callback_no = () => true;

    Questioner (ap) : super(ap) {
        _yesDom = new action.Button().setTitle(INTL.Yes()).setStyle({'float':'right'});
        _noDom = new action.Button().setTitle(INTL.No()).setStyle({'float':'right'});
    }

    set onYes(Function callback_yes) => _callback_yes = callback_yes;

    set onNo(Function callback_no) => _callback_no = callback_no;

    render ({int width: 400, int height: null}) {
        if(_message != null)
            _mesDom.addClass('ui-message').setText(_message);
        if(_details != null)
            _mesDom.addClass('ui-message').append(new SpanElement()..className = 'details'..text = _details);
        var html = new ContainerOption();
        new action.Menu(html).add(_noDom).add(_yesDom);
        Win win = ap.winmanager.loadBoundWin({
            'title': (_title != null)? _title : INTL.Warning(),
            'icon': (_type != null)? _type : 'warning'});
        win.getContent()
            ..addRow(_mesDom)
            ..addRow(html);
        _yesDom.addAction((e) {
            if(_callback_yes())
                win.close();
        }, 'click');
        _noDom.addAction((e) {
            if(_callback_no())
                win.close();
        }, 'click');
        win.render(width, height);
    }
}

class Confirmer extends Messager {
    CLElement okDom;
    Function _callback = () => true;

    Confirmer (ap) : super(ap) {
        okDom = new action.Button().setTitle(INTL.OK()).setStyle({'float':'right'});
    }

    set onOk(Function callback) => _callback = callback;

    render ({int width: 400, int height: null}) {
        if(_message != null)
            _mesDom.addClass('ui-message').setText(_message);
        if(_details != null)
            _mesDom.addClass('ui-message').append(new SpanElement()..className = 'details'..text = _details);
        var html = new ContainerOption();
        new action.Menu(html).add(okDom);
        Win win = ap.winmanager.loadBoundWin({
            'title': (_title != null)? _title : INTL.Warning(),
            'icon': (_type != null)? _type : 'warning'});
        win.getContent()
            ..addRow(_mesDom)
            ..addRow(html);
        okDom.addAction((e) {
            var res = _callback();
            if(res is Future)
                res.then((res) => res? win.close() : null);
            else if(res)
                win.close();
        }, 'click');
        win.render(width, height);
    }
}

class GadgetBase extends CLElement {
	Application ap;
    String title;
	String contr;
	Map params;
    CLElement domContent;

    GadgetBase(this.ap, this.title, [this.contr, this.params]) : super (new CLElement(new DivElement()).setClass('ui-gadget-outer')) {
        createDom();
    }

    createDom () {
        new CLElement(new HeadingElement.h2()).appendTo(this)..dom.text = this.title;
        domContent = new CLElement(new DivElement()).appendTo(this).setClass('ui-gadget-inner');
    }
}

class StatsGadget extends GadgetBase {
    forms.GridBase grid;

    StatsGadget (ap, title) : super(ap, title) {
        domContent.addClass('text');
        grid = new forms.GridBase();
        grid.appendTo(domContent);
        grid.thead.hide();
        grid.tfoot.hide();
    }

    add (title, contr, params) {
        var row = grid.rowCreate();
        var cell_left = grid.cellCreate(row);
        cell_left.className = 'left';
        var cell_right = grid.cellCreate(row);
        cell_right.className = 'right';
        cell_left.text = '$title';
		ap.serverCall(contr, params, domContent).then((d) {
			cell_right.text = '$d';
		});
        return this;
    }

}

class ChartGadget extends GadgetBase {

    ChartGadget (ap, title, contr, params) : super(ap, title, contr, params) {
        domContent.addClass('chart');
    }

	render() => ap.serverCall(contr, params, domContent).then((d) => set(d['chart']));

    set (graph) {
        //print(new DateFormat('','bg_BG').dateSymbols.NARROWWEEKDAYS);
        var ch = new chart.Chart(domContent, domContent.getWidthInner(), domContent.getHeightInner());
		if(graph.length == 0)
			graph.add({'graph': {}, 'label': ''});
		graph.forEach((g) {
			List data = new List();
			g['graph'].forEach((k, v) {
				List d = new List();
				DateTime x = utils.Calendar.parse(k);
				d.add(new DateFormat('d MMM \nyyyy').format(x));
				d.add(v);
				data.add(d);
			});
			ch.addData(data, g['label']);
		});
		ch.initGraph();
		ch.renderGrid();
		ch.renderGraph();
    }

}