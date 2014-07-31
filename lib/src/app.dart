part of app;

class Application {

    Map data;
    Function data_persist = (Map data) => new Future.value(null);

	Element container;

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

	var system;

    Function server_call;

    StatsGadget stats_gadget;

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

        var timer = new CJSElement(new DivElement()).setClass('ui-addon ui-timer').appendTo(addons);
        var timer_func = ([_]) => timer.dom.innerHtml = new DateFormat('Hm', 'en_US').format(new DateTime.now());
        new Timer.periodic(new Duration(seconds:1), timer_func);
        timer_func();
        system = new CJSElement(new AnchorElement()).setClass('ui-addon icon message').appendTo(addons);
	}

    initStartMenu(String title, [String icon]) {
        start_menu = new StartMenu(title, icon);
        menu.append(start_menu.button);
    }

	setMenu (List menu) {
        List desktop = [];
        menu.forEach((i) {
            if(i['desktop'] != null && i['desktop'])
                desktop.add(i);
        });
        start_menu.setMenuLeft(menu);
        iconmanager.set(desktop);
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

    warning (Map o) => new Messager(this)
        ..title = o['title']
        ..message = o['message']
        ..type = o['type']
        ..render();

    setData(String key, String value) {
        data['client']['settings'][key] = value;
    }

    getData(String key) => data['client']['settings'][key];

    Future serverCall(String contr, Map data, [dynamic loading = null]) {
        Completer completer = new Completer();
        server_call(contr, data, completer.complete, loading);
        return completer.future;
    }

    addChartGadget(title, data) {
        var ch = new ChartGadget(title)..appendTo(gadgets);
        ch.set(data);
    }

    addStats(title, value) {
        if(stats_gadget == null)
            stats_gadget = new StatsGadget('Statistics')..appendTo(gadgets);
        stats_gadget.add(title, value);
    }

    _onError(ErrorEvent e) {
    	//e.message;
        new CJSElement(new SpanElement()).appendTo(system).dom.text = '!';
    }

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

	CJSElement container;

	Container win;
	Container win_top;
	Container win_body;

	CJSElement win_title;
	CJSElement win_close;
	CJSElement win_max;
	CJSElement win_min;

	math.MutableRectangle body;
	math.MutableRectangle box;
	math.MutableRectangle box_h;

	bool _maximized 	= false;
	int _zIndex 		= 0;

	int _min_width		= 200;
	int _min_height		= 50;

	CJSElement _resize_cont;
	Rectangle _resize_rect;
	Map _resize_contr;

	math.Point _win_res_pos;
    math.Point _win_diff;
    math.Point _win_bound_low;
    math.Point _win_bound_up;

	utils.Observer observer;

	Win (CJSElement cont) {
		container = cont;
		_createHtml();
		_setWinActions();
		observer = new utils.Observer();
	}

	_createHtml() {
		win = new Container()..setClass('ui-win');
		win_top = new Container()..setClass('title');
		win_body = new Container()..setClass('content');
		win_body.auto = true;

		win_title = new CJSElement(new HeadingElement.h3());
		win_title.dom.text = 'Win';
		win_close = new CJSElement(new AnchorElement())
					..setClass('ui-win-close')
					..addAction((MouseEvent e) => e.stopPropagation(), 'mousedown')
					..addAction((MouseEvent e) => close(), 'click');
		win_max = new CJSElement(new AnchorElement())
					..setClass('ui-win-max')
					..addAction((MouseEvent e) => e.stopPropagation(), 'mousedown')
					..addAction((MouseEvent e) => maximize(), 'click');
		win_min = new CJSElement(new AnchorElement())
					..setClass('ui-win-min')
					..addAction((MouseEvent e) => e.stopPropagation(), 'mousedown')
					..addAction((MouseEvent e) => minimize(), 'click');

		//win.dom.onTransitionEnd.listen((e) => initLayout());

		win_top
			..append(win_title)
			..append(win_close)
			..append(win_max)
			..append(win_min);

		win
			..addRow(win_top)
			..addRow(win_body);

		CJSElement top_left = new CJSElement(new DivElement())..setClass('ui-win-corner-top-left');
		CJSElement top_right = new CJSElement(new DivElement())..setClass('ui-win-corner-top-right');
		CJSElement bottom_left = new CJSElement(new DivElement())..setClass('ui-win-corner-bottom-left');
		CJSElement bottom_right = new CJSElement(new DivElement())..setClass('ui-win-corner-bottom-right');
		CJSElement top = new CJSElement(new DivElement())..setClass('ui-win-top');
		CJSElement right = new CJSElement(new DivElement())..setClass('ui-win-right');
		CJSElement bottom = new CJSElement(new DivElement())..setClass('ui-win-bottom');
		CJSElement left = new CJSElement(new DivElement())..setClass('ui-win-left');

		_resize_cont = new CJSElement(new DivElement())..setClass('ui-win-resize');
		_resize_contr = <String, CJSElement> {
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
				//utils.Point page = new utils.Point(e.page.x, e.page.y);
                _win_diff = page - box.topLeft;
				//_win_diff = page - box.p;
			})
			..on((MouseEvent e) {
                e.stopPropagation();
                Point pos = new Point(e.page.x, e.page.y) - _win_diff;
                pos = utils.boundPoint(pos, _win_bound_low, _win_bound_up);
				//utils.Point pos = new utils.Point(e.page.x, e.page.y);
				//pos = (pos - _win_diff).bound(_win_bound_low, _win_bound_up);
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
		if(title is CJSElement) {
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
		if((width == null || width == 0) && (height == null || height == 0)) {
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
		return this;
	}

	setPosition(int left, int top) {
        box.top = top;
        box.left = left;
        win.setStyle({'top': '${top}px', 'left': '${left}px'});
		_resize_cont.setStyle({'top': '${top}px', 'left': '${left}px'});
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
}

class WinManager {
    Application app;
    String tab_clas = 'ui-win-tab';
    String tab_clas_active = 'ui-win-tab-active';
    List cache_wins = new List();
    List cache_wins_bound = new List();
    CJSElement desk_cont;
    CJSElement tabs_cont;
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
        var div = new CJSElement(new DivElement()).setClass(this.tab_clas),
            span = new CJSElement(new SpanElement()).appendTo(div),
            link = new CJSElement(new AnchorElement()).appendTo(span);
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
    CJSElement container;
    List icons = new List();

    IconManager (this.container);

    add (o) {
        var cont = new CJSElement(new AnchorElement())
        .addAction((e) => o['action']());
        new CJSElement(new DivElement())
        .setClass('${o['icon']} icon-big')
        .appendTo(cont);
        var h3 = new CJSElement(new HeadingElement.h3())
        .appendTo(cont);
        cont.addClass('desktop-icon');
        cont.addClass('right-tip');
        cont.dom.setAttribute('data-tips', o['title']);
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

class StartMenu extends CJSElement {

    String title, icon;

    CJSElement cont_top, cont_body, cont_left, cont_right, button;

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
        cont_top = new CJSElement(new DivElement()).setClass('ui-start-menu-top')
            .appendTo(this)
            .addAction(_domClick,'click');
        cont_body = new CJSElement(new DivElement())
            .setClass('ui-start-menu-body')
            .appendTo(this);
        cont_left = new CJSElement(new DivElement())
            .setClass('ui-start-menu-left')
            .appendTo(cont_body)
            .addAction(_domClick,'click');
        cont_right = new CJSElement(new DivElement())
            .setClass('ui-start-menu-right')
            .appendTo(cont_body)
            .addAction(_domClick,'click');
    }

    createButton () {
        button = new CJSElement(new AnchorElement())
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
        var doc = new CJSElement(document);
		doc.addAction((e) {
            removeMenu();
            doc.removeAction('click.start');
        }, 'click.start');
        rendered = true;
        return this;
    }

    setMenuLeft (arr) {
        var map = {};
        map['main'] = new StartMenuElement();
        arr.forEach((obj) {
            var o = {
                'title': obj['title'],
                'icon': obj['icon_ref'] != null? obj['icon_ref'] : obj['icon'],
                'action': obj['action'],
                'ref': obj['ref'] != null? obj['ref'] : '',
                'key': obj['key'] != null? obj['key'] : '',
                'desktop': obj['desktop']
            };
			o['_m'] = this;
            //if(o['ref'].isNotEmpty) {
              //  print('d');
                map[o['key']] = map[o['ref']].add(o);
            //}
        });
        menu = map['main'];
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
        var u = new CJSElement(new SpanElement())
            .setClass('ui-app-user icon user')
            .appendTo(this.cont_top);
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

class StartMenuElement extends CJSElement {
    String title, icon;

    Function action;
    List childs = new List();

	StartMenuElement parent;

    CJSElement cont;

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
        var a = new CJSElement(new AnchorElement())
            .addAction((e) => action(), 'click')
			.addAction((e) => _m.removeMenu(), 'click')
            .appendTo(this);
		if(icon != null)
			a.setClass(icon + ' icon');
		a.dom.innerHtml = title;
    }

    add (Map el) {
        var child = new StartMenuElement(el);
        child.level++;
        child.parent = this;
        childs.add(child);
        addClass('ui-start-menu-childs');
        return child;
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
            cont = new CJSElement(new DivElement())
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
        var diff = reach - new CJSElement(document.body).getHeight();
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

class UnactivePage extends CJSElement {

    UnactivePage (Application app, [int zIndex = 889]) : super(new DivElement()) {
        var el = document.getElementById('ui-unactivepage');
        if (el != null) {
            el.remove();
        } else {
            var container = new CJSElement(app.container).setStyle({'position':'relative'});
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

class Hint extends CJSElement {
    Function callBack;
    int time = 300;
    var timer_show, timer_close;
    CJSElement hintDom;

    Hint () : super(new AnchorElement()) {
        setHtml('?');
        addAction(_startShow, 'mouseover');
        addAction(_stopShow, 'mouseout');
        addAction(_startClose, 'mouseout');

        hintDom = new CJSElement(new DivElement())
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
        if ((left + 220) > new CJSElement(document.body).getWidth())
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
    CJSElement hint;
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
        var c = new CJSElement(new DivElement()).setClass('ui-hint-spot');
        var t = new CJSElement(new SpanElement())
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
            ap.serverCall(route.reverse([key]), {'locale': Intl.locale}, null).then((response) {
                if(response != null)
                    data[key]['data'] = response;
                data[key]['hint'].setData(data[key]['data']);
            });
        }
    }
}

class Messager {
    Application ap;
    String _type, _title, _message;
    CJSElement _mesDom;

    Messager (this.ap) {
        createDom();
    }

    createDom() => _mesDom = new ContainerDataLight();

    get container => _mesDom;

    set title(String title) => _title = title;

    set type(String type) => _type = type;

    set message(String message) => _message = message;

    render ({int width: 500, int height: null}) {
        Win win = ap.winmanager.loadBoundWin({
            'title': _title,
            'icon': (_type != null)? _type : 'attention'});
        if(_message != null)
            _mesDom.addClass('ui-message').setText(_message);
        win.getContent().addRow(_mesDom);
        win.render(width, height);
    }
}

class Questioner extends Messager {
    CJSElement _yesDom, _noDom;
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
    CJSElement _okDom;
    Function _callback = () => true;

    Confirmer (ap) : super(ap) {
        _okDom = new action.Button().setTitle(INTL.OK()).setStyle({'float':'right'});
    }

    set onOk(Function callback) => _callback = callback;

    render ({int width: 400, int height: null}) {
        if(_message != null)
            _mesDom.addClass('ui-message').setText(_message);
        var html = new ContainerOption();
        new action.Menu(html).add(_okDom);
        Win win = ap.winmanager.loadBoundWin({
            'title': (_title != null)? _title : INTL.Warning(),
            'icon': (_type != null)? _type : 'warning'});
        win.getContent()
            ..addRow(_mesDom)
            ..addRow(html);
        _okDom.addAction((e) {
            if(_callback())
                win.close();
        }, 'click');
        win.render(width, height);
    }
}

class GadgetBase extends CJSElement {
    String title;
    CJSElement domContent;

    GadgetBase(this.title) : super (new CJSElement(new DivElement()).setClass('ui-gadget-outer')) {
        createDom();
    }

    createDom () {
        new CJSElement(new HeadingElement.h2()).appendTo(this)..dom.text = this.title;
        domContent = new CJSElement(new DivElement()).appendTo(this).setClass('ui-gadget-inner');
    }
}

class StatsGadget extends GadgetBase {
    forms.GridBase grid;

    StatsGadget (title) : super(title) {
        domContent.addClass('text');
        grid = new forms.GridBase();
        grid.appendTo(domContent);
        grid.thead.hide();
        grid.tfoot.hide();
    }

    add (title, value) {
        var row = grid.rowCreate();
        var cell_left = grid.cellCreate(row);
        cell_left.className = 'left';
        var cell_right = grid.cellCreate(row);
        cell_right.className = 'right';
        cell_left.text = '$title';
        cell_right.text = '$value';
        return this;
    }

}

class ChartGadget extends GadgetBase {

    ChartGadget (title) : super(title) {
        domContent.addClass('chart');
    }

    set (graph) {
        //print(new DateFormat('','bg_BG').dateSymbols.NARROWWEEKDAYS);
        var ch = new chart.Chart(domContent, domContent.getWidthInner(), domContent.getHeightInner());
        List data = new List();
        graph.forEach((k, v) {
            List d = new List();
            DateTime x = utils.Calendar.parse(k);
            d.add(new DateFormat('d MMM \nyyyy').format(x));
            d.add(v);
            data.add(d);
        });
        ch.setData(data);
        ch.initGraph();
        ch.renderGrid();
        ch.renderGraph();
    }

}