part of action;

class Button extends CLElement {
    CLElement<ButtonElement> domAction;
    List sub = new List();
	String _name;

    Button () : super (new SpanElement()) {
		setClass('ui-button');
        domAction = new CLElement(new ButtonElement()).setClass('ui-button-inner').appendTo(this);
        setState(true);
    }

	setName(String name) {
		_name = name;
		return this;
	}

	getName() => _name;

    addSub (button) {
        sub.add(button);
		var ul = new CLElement(new UListElement())..appendTo(this);
		new CLElement(new LIElement())..appendTo(ul).append(button);
        return this;
    }

    setIcon (icon, [pos]) {
        domAction.addClass(icon + ' icon');
        if (pos != null)
            domAction.setStyle({'backgroundPosition': pos});
        return this;
    }

    setWidth(int width, [String unit = 'px']) {
        domAction.setWidth(width, unit);
        return this;
    }

    setTip(String text, [String pos = 'bottom']) {
        CLElement tip;
        Timer timer;
        bool offset_top = false;
        bool offset_left = false;
        switch(pos) {
            case 'top': offset_top = false; break;
            case 'bottom': offset_top = true; break;
            case 'left': offset_left = false; break;
            case 'right': offset_left = true; break;
        }
        addAction((e) {
            if(state) {
                var rect = getRectangle();
                tip = new CLElement(new DivElement())
                    ..addClass('ui-data-tip $pos-tip')
                    ..setAttribute('data-tips', text)
                    ..setStyle({
                        'top':'${rect.top + ((offset_top)? rect.height : 0)}px',
                        'left':'${rect.left + ((offset_left)? rect.width : 0)}px'
                    })
                    ..appendTo(document.body);
                timer = new Timer(new Duration(milliseconds:100), () => tip.addClass('show'));
            }
        }, 'mouseover');
        addAction((e) {
            if(state) {
                timer.cancel();
                tip.remove();
            }
        }, 'mouseout');
        return this;
    }

    setTitle (title) {
        if (title != null) {
            domAction.dom.text = title;
			domAction.addClass('ui-button-title');
        } else
            domAction.removeClass('ui-button-title');
        return this;
    }

    disable () => setState(false);

	enable () => setState(true);

    setState (state) {
        super.setState(state);
        if (state)
            removeClass('ui-button-disabled').addClass('ui-button-active');
        else
            removeClass('ui-button-active').addClass('ui-button-disabled');
        return this;
    }
}

class ButtonOption extends CLElement {
    Button domAction;
    Button domActionOptions;
    CLElement domList;
    bool _showed = false;
    List sub = new List();
    String _name;

    bool _dropDown = true;

    ButtonOption () : super (new SpanElement()) {
        setClass('ui-button-option');
        domAction = new Button().appendTo(this).addClass('ui-main');
        domActionOptions = new Button().appendTo(this).addClass('ui-option');
        domActionOptions.addAction(_showList,'click');
        domList = new CLElement(new UListElement()).addClass('ui-button-option-ul').appendTo(this).hide();
        setState(true);
    }

    _addDocAction(doc) {
        doc.addAction((MouseEvent e) {
            doc.removeAction('mousedown.button_option');
            if(sub.any((but) => but.domAction.dom != e.target))
                _showList(e);
        },'mousedown.button_option');
    }

    setName(String name) {
        _name = name;
        return this;
    }

    set dropDown(bool dropDown) {
        _dropDown = dropDown;
    }

    getName() => _name;

    addSub (button) {
        sub.add(button);
        button.addAction((e) => e.stopPropagation(), 'mousedown');
        button.addAction((e) => _hideL(), 'click');
        new CLElement(new LIElement()).append(button).appendTo(domList);
        return this;
    }

    _showList([e]) {
        if(!_showed)
            _showL();
        else
            _hideL();
    }

    _showL() {
        domList.show();
        _showed = true;
        var way = _dropDown? 'down' : 'up';
        addClass('ui-open $way');
        var pos = domList.getRectangle(),
        width = getWidth(),
        height = domAction.getHeight();
        domList.appendTo(document.body)
        .addClass(way)
        .setStyle({
            'position':'absolute',
            'top':'${pos.top + height - (_dropDown? 0 : (domList.getHeight() + getHeight() - 1))}px',
            'left':'${pos.left}px',
            'width': '${width}px'});
        var doc = new CLElement(document);
        doc.addAction((MouseEvent e) {
            doc.removeAction('mousedown.button_option');
            if(sub.any((but) => but.domAction.dom != e.target))
                _showList(e);
        },'mousedown.button_option');
    }

    _hideL() {
        domList.hide();
        _showed = false;
        removeClass('ui-open');
        domList.appendTo(this)
        .setStyle({
            'position':'relative',
            'top':'0px',
            'left':'0px'});
        domList.hide();
        new CLElement(document).removeAction('mousedown.button_option');
    }

    setIcon (icon, [pos]) {
        domAction.setIcon(icon, pos);
        return this;
    }

    setTitle (title) {
        domAction.setTitle(title);
        return this;
    }

    disable () => setState(false);

    enable () => setState(true);

    setState (state) {
        _hideL();
        domAction.setState(state);
        domActionOptions.setState(state);
        return this;
    }

    addAction(func, [event = 'click']) {
        domAction.addAction(func, event);
        return this;
    }
}

class ButtonGroup extends CLElement {
    Button current;
    CLElement domList;
    List sub = new List();

    ButtonGroup () : super (new SpanElement()) {
        setClass('ui-button-group');
        domList = new CLElement(new UListElement()).addClass('ui-button-ul').appendTo(this);
    }

    addSub (button) {
        sub.add(button);
        int num = sub.length - 1;
        button.addAction((e) => setCurrent(num), 'click');
        new CLElement(new LIElement()).append(button).appendTo(domList);
        return this;
    }

    setCurrent([int num]) {
        sub.forEach((b) => b.removeClass('current'));
        if(num != null) {
            sub[num].addClass('current');
            current = sub[num];
        }
    }

}

class Link extends CLElement {
  	CLElement domAction;

  	Link () : super(new SpanElement()) {
		domAction = new CLElement(new AnchorElement()).appendTo(this);
  	}

  	setIcon (icon, [pos]) {
      	domAction.setClass(icon + ' icon');
      	if (pos)
          	domAction.setStyle({'backgroundPosition': pos});
      	return this;
  	}

  	setTitle (title) {
      	domAction.dom.text = title;
		domAction.setStyle({'paddingRight':'3px'});
        return this;
    }

}

class Menu extends ElementCollection {
    CLElement container;

    Menu (this.container) {
        container.addClass('ui-menu');
    }

    add (el) {
        super.add(el);
        container.append(el);
        return this;
    }

    remove (name) {
        var el = super.remove(name);
        if (el != null)
            container.removeChild(el);
    }

    initButtons ([List arr]) {
        indexOfElements.forEach((el) => el.setState(false));
        if(arr is List)
            arr.forEach((name) => this[name].setState(true));
    }

    hide  () {
        container.hide();
        return this;
    }

    show () {
        container.show();
        return this;
    }
}

class FileUploader extends Button {
    app.Application ap;

    static const String hook_before = 'hook_before';
    static const String hook_loading = 'hook_loading';
    static const String hook_loaded = 'hook_loaded';

    CLElement input;
    dynamic id;
    utils.Observer observer;

    String upload;

    FileUploader ([this.ap]) : super () {
        observer = new utils.Observer();
        createForm();
        setStyle({'position':'relative','overflow':'hidden'}).append(input);
    }

    setUpload (String upload) {
        this.upload = upload;
        return this;
    }

    setState (bool state) {
        super.setState(state);
        if(input == null)
            return this;
        if(!state)
            input.hide();
        else
            input.show();
        return this;
    }

    createForm () {
        input = new CLElement(new InputElement());
        input.dom
            ..type = 'file'
            ..name = 'filename[]'
            ..multiple = true;
        input.setStyle({
            'opacity':'0',
            'position':'absolute',
            'top':'-100px',
            'right':'0px',
            'font-size':'200px',
            'cursor':'pointer',
            'text-align':'right'
        })
        .addAction((e) {
            if(input.dom.files.length > 0) {
                input.dom.files.forEach((f) {
                    var fr = new FileReader();
                    fr.onLoad.listen((e) => _upload(f.name, fr.result.split(',').last));
                    fr.readAsDataUrl(f);
                });
            }
        }, 'change');
    }

    _upload(name, content) {
        observer.execHooks(hook_loading, name);
        ap.serverCall('/file/upload', {'object': name, 'base': upload, 'content': content})
        .then((data) => observer.execHooks(hook_loaded, name));
    }

}

/*class FileUploader extends Button {
    app.Application ap;

    static const String hook_before = 'hook_before';
    static const String hook_loading = 'hook_loading';
    static const String hook_loaded = 'hook_loaded';

    CLElement form;
    dynamic id;
    utils.Observer observer;

    String upload;

    FileUploader ([this.ap]) : super () {
        observer = new utils.Observer();
        createForm();
        setStyle({'position':'relative','overflow':'hidden'}).append(form);
    }

    setUpload (String upload) {
        this.upload = upload;
        return this;
    }

    setState (bool state) {
        super.setState(state);
        if(form == null)
            return this;
        if(!state)
            form.hide();
        else
            form.show();
        return this;
    }

    createForm () {
        form = new CLElement(new FormElement());
        form.dom.method = 'post';
        form.dom.enctype = 'multipart/form-data';
        var input = new CLElement(new InputElement());
        input.dom.type = 'file';
        input.dom.name = 'filename[]';
        input.dom.multiple = true;
        input.setStyle({
            'opacity':'0',
            'position':'absolute',
            'top':'-100px',
            'right':'0px',
            'font-size':'200px',
            'cursor':'pointer',
            'text-align':'right'
        })
        .addAction((e) {
            if(input.dom.files.length > 0) {
                input.dom.files.forEach((f) {
                    var fr = new FileReader();
                    fr.onLoad.listen((e) {
                        ap.serverCall('/file/upload', {'object':f.name, 'base': '../tmp', 'content':fr.result.split(',').last});
                    });
                    fr.readAsDataUrl(f);
                });
                var fs = [];
                input.dom.files.forEach((f) => fs.add(f.name));
                submit(fs);
            }
        }, 'change')
        .appendTo(form);
    }

    submit (List filenames) {
        var iframe_cont, iframe;
        var clean = () => iframe_cont.remove();
        var frame = () {
            var n = 'f${new Random().nextInt(1000) * 99999}';
            iframe_cont = new CLElement(new DivElement()).appendTo(document.body);
            iframe = new CLElement(new IFrameElement());
            iframe.dom.src = 'about:blank';
            iframe.dom.id = n;
            iframe.dom.name = n;
            iframe.setStyle({'display':'none'}).appendTo(iframe_cont);
            return n;
        };
        var loaded = () {
            observer.execHooks(hook_loaded, filenames);
            clean();
        };
        var submitForm = (f) {
            f.dom.target = frame();
            if(observer.execHooks(hook_before, filenames)) {
                observer.execHooks(hook_loading, filenames);
                iframe.addAction((e) => loaded(),'load');
                f.dom.submit();
            } else {
                clean();
            }
        };
        submitForm(form);
        return true;
    }

}*/