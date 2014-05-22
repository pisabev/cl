part of app;

class Application {

    Map data;

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

	Application([Container cont]) {
		container = (cont != null)? cont : document.body;
		_createHtml();

		winmanager = new WinManager(this);
    	resourcemanager = new ResourceManager();
        iconmanager = new IconManager(desktop);
		window.onResize.listen((e) => initLayout());
        window.onError.listen((e) => new CJSElement(new SpanElement()).appendTo(system).dom.text = '!');
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

    warning (Map o) => new Messager(this, o).show();

}

class WinApp {
    Application app;
    Map w;
    Win win;

    WinApp (this.app);

    load (Map data, Item obj, [int startZIndex]) {
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

	utils.Box body;
	utils.Box box;
	utils.Box box_h;

	bool _maximized 	= false;
	int _zIndex 		= 0;

	int _min_width		= 200;
	int _min_height		= 50;

	CJSElement _resize_cont;
	Map _resize_pointer;
	Map _resize_contr;

	utils.Point _win_res_pos;
	utils.Point _win_diff;
	utils.Point _win_bound_low;
	utils.Point _win_bound_up;

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

		win.dom.onTransitionEnd.listen((e) => initLayout());

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
		new utils.Draggable(win_top, 'stop')
			..observer.addHook('start', (list) {
				MouseEvent e = list[0];
				win.addClass('transform');
				utils.Point page = new utils.Point(e.page.x, e.page.y);
				_win_diff = page - box.p;
			})
			..observer.addHook('on', (list) {
				MouseEvent e = list[0];
                e.stopPropagation();
				utils.Point pos = new utils.Point(e.page.x, e.page.y);
				pos = (pos - _win_diff).bound(_win_bound_low, _win_bound_up);
				setPosition(pos.x, pos.y);
			})
			..observer.addHook('stop', (list) => win.removeClass('transform'));

		new utils.Draggable(_resize_contr['t_c'], 'stop')
			..observer.addHook('start', (list) => _winResizeBefore(list[0]))
			..observer.addHook('on', (list) => _winResizeOn('N', list[0]))
			..observer.addHook('stop', _winResizeAfter);
		new utils.Draggable(_resize_contr['r_c'], 'stop')
			..observer.addHook('start', (list) => _winResizeBefore(list[0]))
			..observer.addHook('on', (list) => _winResizeOn('E', list[0]))
			..observer.addHook('stop', _winResizeAfter);
		new utils.Draggable(_resize_contr['b_c'], 'stop')
			..observer.addHook('start', (list) => _winResizeBefore(list[0]))
			..observer.addHook('on', (list) => _winResizeOn('S', list[0]))
			..observer.addHook('stop', _winResizeAfter);
		new utils.Draggable(_resize_contr['l_c'], 'stop')
			..observer.addHook('start', (list) => _winResizeBefore(list[0]))
			..observer.addHook('on', (list) => _winResizeOn('W', list[0]))
			..observer.addHook('stop', _winResizeAfter);
		new utils.Draggable(_resize_contr['t_l_c'], 'stop')
			..observer.addHook('start', (list) => _winResizeBefore(list[0]))
			..observer.addHook('on', (list) => _winResizeOn('NW', list[0]))
			..observer.addHook('stop', _winResizeAfter);
		new utils.Draggable(_resize_contr['t_r_c'], 'stop')
			..observer.addHook('start', (list) => _winResizeBefore(list[0]))
			..observer.addHook('on', (list) => _winResizeOn('NE', list[0]))
			..observer.addHook('stop', _winResizeAfter);
		new utils.Draggable(_resize_contr['b_l_c'], 'stop')
			..observer.addHook('start', (list) => _winResizeBefore(list[0]))
			..observer.addHook('on', (list) => _winResizeOn('SW', list[0]))
			..observer.addHook('stop', _winResizeAfter);
		new utils.Draggable(_resize_contr['b_r_c'], 'stop')
			..observer.addHook('start', (list) => _winResizeBefore(list[0]))
			..observer.addHook('on', (list) => _winResizeOn('SE', list[0]))
			..observer.addHook('stop', _winResizeAfter);
	}

	_winResizeBefore(MouseEvent e) {
		e.stopPropagation();
		_win_res_pos = new utils.Point(e.page.x, e.page.y);
		win.addClass('transform');
		container.append(_resize_cont);
	}

	_winResizeOn(String destination, MouseEvent e) {
		e.stopPropagation();
		utils.Point pos = new utils.Point(e.page.x, e.page.y);
		pos = pos.bound(new utils.Point(body.p.x, body.p.y), new utils.Point(body.p.x + body.w - 10, body.p.y + body.h - 10));
		utils.Point diff_pos = _win_res_pos - pos;

		Function calc = (int dim, [String type = 'width']) {
			return (type == 'width')? Math.max(dim, _min_width) : Math.max(dim, _min_height);
		};

		var p = {
			'left': box.p.x,
			'top': box.p.y,
			'width': box.w,
			'height': box.h
		};

		switch(destination) {
			case 'N':
				p['height'] = calc(p['height'] + diff_pos.y, 'height');
				p['top'] = p['top'] + (box.h - p['height']);
				break;
			case 'E':
				p['width'] = calc(p['width'] - diff_pos.x);
				break;
			case 'S':
				p['height'] = calc(p['height'] - diff_pos.y, 'height');
				break;
			case 'W':
				p['width'] = calc(p['width'] + diff_pos.x);
				p['left'] = p['left'] + (box.w - p['width']);
				break;
			case 'SE':
				p['width'] = calc(p['width'] - diff_pos.x);
				p['height'] = calc(p['height'] - diff_pos.y, 'height');
				break;
			case 'SW':
				p['width'] = calc(p['width'] + diff_pos.x);
				p['height'] = calc(p['height'] - diff_pos.y, 'height');
				p['left'] = p['left'] + (box.w - p['width']);
				break;
			case 'NW':
				p['width'] = calc(p['width'] + diff_pos.x);
				p['height'] = calc(p['height'] + diff_pos.y, 'height');
				p['left'] = p['left'] + (box.w - p['width']);
				p['top'] = p['top'] + (box.h - p['height']);
				break;
			case 'NE':
				p['width'] = calc(p['width'] - diff_pos.x);
				p['height'] = calc(p['height'] + diff_pos.y, 'height');
				p['top'] = p['top'] + (box.h - p['height']);
				break;
		}

		_resize_cont
			..setWidth(p['width'])
			..setHeight(p['height'])
			..setStyle({'left': p['left'].toString() + 'px', 'top': p['top'].toString() + 'px'});
		_resize_pointer = p;
	}

	_winResizeAfter(list) {
		_resize_cont.remove();
		if(_resize_pointer != null && !_resize_pointer.isEmpty) {
			var p = _resize_pointer;
			setSize(p['width'], p['height']);
			setPosition(p['left'], p['top']);
			initLayout();
			_resize_pointer = new Map();
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
		if(_maximized == true) {
			win.addClass('ui-win-shadowed');
			win_top.state = true;
            if(box_h.w == 0 && box_h.h == 0) {
                box_h.w = box.w - 100;
                box_h.h = box.h - 100;
                box_h.p.x = 50;
                box_h.p.y = 50;
            }
			setSize(box_h.w, box_h.h);
			setPosition(box_h.p.x, box_h.p.y);
			_maximized = false;
			_resize_contr.forEach((k, v) => v.show());
			initLayout();
		} else {
			win.removeClass('ui-win-shadowed');
			box_h = new utils.Box(box.p.x, box.p.y, box.w, box.h);
			setSize(body.w, body.h);
			_maximized = true;
			win_top.state = false;
			_resize_contr.forEach((k, v) => v.hide());
			initPosition(body.p.x, body.p.y);
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
		Map pos = container.getPosition();
		body = new utils.Box(pos['left'], pos['top'],
			container.getWidthInner(),
			container.getHeightInner());
		box = new utils.Box(0, 0, 0, 0);
		win.appendTo(container);
		if((width == null || width == 0) && (height == null || height == 0)) {
			maximize();
		} else {
            _setWidth(Math.max(width,_min_width));
            _setHeight(height != null? Math.max(height, _min_height) : Math.min(win.getHeight(), container.getHeightInner()));
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
		box.p.y = top;
        box.p.x = left;
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
        box.w = width;
        int w = width - win.getWidthInnerShift();
        win.setWidth(w);
        _resize_contr['t_c'].setWidth(w);
        _resize_contr['b_c'].setWidth(w);
        _resize_cont.setWidth(width - _resize_cont.getWidthInnerShift());
    }

    _setHeight(int height) {
        box.h = height;
        int h = height - win.getHeightInnerShift();
        win.setHeight(h);
        _resize_contr['l_c'].setHeight(h);
        _resize_contr['r_c'].setHeight(h);
        _resize_cont.setHeight(height - _resize_cont.getHeightInnerShift());
    }

    _initSize() {
        _win_bound_low = new utils.Point(body.p.x, body.p.y);
        _win_bound_up = new utils.Point(body.w - box.w, body.h  - box.h);
    }

	initPosition([int x, int y]) {
		if(!_maximized) {
			box = box.center(body);
			if (x != 0 && y != 0) {
				box = new utils.Box(x, y, box.w, box.h);
				box = box.bound(body);
			}
			setPosition(box.p.x, box.p.y);
		} else {
			setPosition(body.p.x, body.p.y);
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
        var pos = button.getPosition();
        document.body.append(this.dom);
        var count = menu.childs.length;
        var height = menu.childs[0].getHeight();
        cont_body.setHeight(count*height + 50);
        setStyle({'top':(pos['top'] - getHeight()).toString() + 'px', 'left':pos['left'].toString() + 'px'});
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
            b.addAction((e) => o['action']);
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
            var pos = getPosition();
            cont.setStyle({'position':'absolute',
						'top': pos['top'].toString() + 'px',
						'left': (pos['left'] + 200).toString() + 'px',
						'height': height.toString() + 'px'});
        }
        document.body.append(cont.dom);
        _fixHeight();
    }

    _fixHeight() {
        var pos = getPosition();
        var reach = pos['top'] + cont.getHeight();
        var diff = reach - new CJSElement(document.body).getHeight();
        var top = pos['top'];
        if (diff > 0)
            top -= diff;
        cont.setStyle({'position':'absolute', 'top': top.toString() + 'px'});
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

class Messager {
    Application ap;
    String _type, _title, _message;
    CJSElement mesDom;

    Messager (this.ap, [Map o]) {
        mesDom = new ContainerData();
        mesDom.setStyle({'padding':'10px'});
        if(o is Map) {
            setTitle(o['title']);
            setMessage(o['message']);
            setType(o['type']);
        }
    }

    setType ([String type]) {
        _type = (type != null)? type : 'attention';
        return this;
    }

    setTitle ([String title]) {
        _title = (title != null)? title : '';
        return this;
    }

    setMessage ([String message]) {
        _message = (message != null)? message : '';
        return this;
    }

    show ({int width: 500, int height: null}) {
        Win win = ap.winmanager.loadBoundWin({'title': _title, 'icon': _type});
        mesDom.dom.innerHtml = _message;
        win.getContent().addRow(mesDom);
        win.render(width, height);
    }
}

class Item {

	Map w = {'title': 'Window'};
	WinApp wapi;

}