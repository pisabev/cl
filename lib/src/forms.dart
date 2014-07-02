part of forms;

class Data {

    static const String hook_value = 'hook_value';
    static const String hook_require = 'hook_require';

    bool _send          = true;
    bool _required      = false;
    bool _valid         = true;
    String _context;
    String _name;
    dynamic _value;

    utils.Observer observer = new utils.Observer();

    stop () {
        _send = false;
        return this;
    }

    setName(String name) {
        _name = name;
        return this;
    }

    getName() => _name;

    setContext (String context) {
        _context = context;
        return this;
    }

    getContext () => _context;

    setValue (dynamic value, [bool silent = false]) {
        _value = value;
        if (!silent)
            execHooks(hook_value);
        return this;
    }

    getValue () => _value;

    addHook (String hook, Function func) {
        observer.addHook(hook, func);
        return this;
    }

    setRequired(bool required) {
        _required = required;
        return this;
    }

    isReady () {
        var value = getValue();
        if((_required && (value == null || value == '')) || !_valid) {
            execHooks(hook_require);
            return false;
        } else {
            return true;
        }
    }

    execHooks (String scope, [list]) => observer.execHooks(scope, list);

}

class DataList extends Data {
    List arr_data = new List();

    setValue (List arr, [bool silent = false]) {
        if (arr != null && arr.length > 0) {
            var form = new Form();
            arr.forEach((el) {
                el.addHook(Data.hook_value, observer.getHook(Data.hook_value));
                el.addHook(Data.hook_require, observer.getHook(Data.hook_require));
                form.add(el);
            });
            arr_data.add(form);
        }
        else
            arr_data = [];
        if (!silent)
            execHooks(Data.hook_value);
        return this;
    }

    getValue  () {
        var arr = [];
        arr_data.forEach((form) => arr.add(form.toOBJ()));
        return arr;
    }
}

class DataElement<E> extends CJSElement<E> with Data {

    DataElement (dom) : super(dom);

}

class FormElement<E extends InputElementBase> extends DataElement<E> {

    FormElement (dom) : super(dom);

    setState(bool way) {
        state = !!way;
        return this;
    }

    focus() {
        dom.focus();
        return this;
    }

    blur() {
        dom.blur();
        return this;
    }

    disable() {
        setState(false);
        dom.disabled = true;
        return this;
    }

    enable() {
        setState(true);
        dom.disabled = false;
        return this;
    }

}

class InputField<E extends InputElement> extends FormElement<E> {

    static const String hook_validate_error = 'hook_validate_error';
    static const String hook_validate_ok = 'hook_validate_ok';
    static const String INT = 'int';
    static const String FLOAT = 'float';
    static const String DATE = 'date';

    List _validate_value = new List();
    List _validate_input = new List();

    String type;

    InputField (E element, [this.type]) : super (element) {
        switch(this.type) {
            case INT:
                addValidation((e) {
                    var v = new utils.EventValidator(e);
                    return new Future.value(v.isBasic() || v.isNum() || v.isPlus() || v.isMinus());
                }, onInput: true);
                break;
            case FLOAT:
                addValidation((e) {
                    var v = new utils.EventValidator(e);
                    return new Future.value(v.isBasic() || v.isNum() || v.isPlus() || v.isMinus() || v.isPoint());
                }, onInput: true);
                break;
            case DATE:
                addValidation((e) {
                    var v = new utils.EventValidator(e);
                    return new Future.value(v.isBasic() || v.isNum() || v.isSlash());
                }, onInput: true);
                break;
        }
        addAction(_validateValue, 'blur');
        addAction(_validateInput, 'keydown');
        addAction((e) {
            var sel_start = dom.selectionStart,
            sel_end = dom.selectionEnd;
            setValue(dom.value, false);
            dom.selectionStart = sel_start;
            dom.selectionEnd = sel_end;
        }, 'keyup');
    }

    setValue(dynamic value, [bool silent = false]) {
        if(type == INT) {
            dom.value = (value == null)? '' : value.toString();
            if(value is String)
                value = (!value.isEmpty)? int.parse(value) : null;
            super.setValue(value, silent);
        } else if(type == FLOAT) {
            dom.value = (value == null)? '' : value.toString();
            if(value is String)
                value = (!value.isEmpty)? double.parse(value) : null;
            super.setValue(value, silent);
        } else if(type == DATE) {
            if(value is String)
                value = utils.Calendar.parse(value);
            super.setValue(value, silent);
            if(value == null)
                dom.value = '';
            else
                dom.value = utils.Calendar.string(value);
        } else {
            dom.value = (value == null)? '' : value.toString();
            super.setValue(value, silent);
        }
        return this;
    }

    Future _validateValue (e) {
        return Future.wait(_validate_value.map((f) => f(e))).then((List res) {
            if(res.any((r) => r == false)) {
                _valid = false;
                execHooks(hook_validate_error);
            } else {
                _valid = true;
                execHooks(hook_validate_ok);
            }
        });
    }

    Future _validateInput (e) {
        return Future.wait(_validate_input.map((f) => f(e))).then((List res) {
            if(res.any((r) => r == false)) {
                e.preventDefault();
                execHooks(hook_validate_error);
            } else {
                execHooks(hook_validate_ok);
            }
        });
    }

    addValidation(Function func, {onInput: false}) {
        if(onInput)
            _validate_input.add(func);
        else
            _validate_value.add(func);
        return this;
    }

}

class TextAreaField extends InputField<TextAreaElement> {

    TextAreaField () : super (new TextAreaElement());

}

class Text extends DataElement {

	Text ([Element el]) : super ((el != null)? el : new SpanElement());

	setValue (dynamic value, [bool silent = false]) {
		value = value.toString();
		super.setValue(value, silent);
		dom.text = value;
		return this;
	}
}

class SelectField extends FormElement<SelectElement> {

	SelectField () : super (new SelectElement()) {
		addAction((e) => setValue(dom.value, false), 'change');
	}

    setValue(dynamic value, [bool silent = false]) {
        super.setValue(value, silent);
        dom.value = value.toString();
        return this;
    }

}

abstract class _FieldBuilder<E extends FormElement> extends DataElement<SpanElement> {
	E field;

	_FieldBuilder (this.field) : super(new SpanElement()) {
        append(field);
        field.addAction((e) => focus(), 'focus');
        field.addAction((e) => blur(), 'blur');
    }

    onTypeError () {
        addClass('error');
        return false;
    }

    onTypeOk () {
        removeClass('error');
        return true;
    }

    setRequired (bool required) {
        field.setRequired(required);
        if  (required) {
            field.addHook(Data.hook_require, () {
                addClass('error');
                return true;
            });
        }
        return this;
    }

    isReady() => field.isReady();

    focus () {
        addClass('focus');
		field.focus();
        return this;
    }

    blur () {
        removeClass('focus');
		field.blur();
        return this;
    }

    setValue (dynamic value, [bool silent = false]) {
        field.setValue(value, silent);
        return this;
    }

    setClass (clas) {
        addClass(clas);
        return this;
    }

    getValue () => field.getValue();

    setState(way) {
        field.setState(way);
        return this;
    }

    addHook (String hook, Function func) {
        field.addHook(hook, func);
        return this;
    }

    addAction (Function func, [event]) {
        field.addAction(func, event);
        return this;
    }

}

class Input extends _FieldBuilder<InputField> {

	Input([type]) : super(new InputField(new InputElement(), type)) {
		setClass('ui-field-input');
        field.addHook(InputField.hook_validate_error, onTypeError);
    	field.addHook(InputField.hook_validate_ok, onTypeOk);
	}

	setPlaceHolder(String value) {
		field.dom.placeholder = value;
	  	return this;
	}

    addValidation (Function func) {
        field.addValidation(func);
        return this;
    }

	select() {
        field.dom.select();
        return this;
    }

	disable() {
		field.disable();
		return this;
	}

	enable() {
		field.enable();
		return this;
	}

}

class TextArea extends _FieldBuilder<TextAreaField> {

	TextArea () : super(new TextAreaField()) {
        setClass('ui-field-input textarea');
        field.addHook(InputField.hook_validate_error, onTypeError);
        field.addHook(InputField.hook_validate_ok, onTypeOk);
    }

	disable() {
		field.disable();
		return this;
	}

	enable() {
		field.enable();
		return this;
	}

}

class Check extends FormElement<CheckboxInputElement> {

	Check () : super (new CheckboxInputElement()) {
        addAction((e) => setValue(getValue(), false), 'click');
    }

    setChecked (bool checked) {
        dom.checked = checked;
        return this;
    }

    isChecked () => dom.checked;

    toggle () {
        dom.checked = !dom.checked;
        return this;
    }

    setValue (dynamic value, [bool silent = false]) {
        dom.checked = (value == null || value == 0)? false : true;
        dom.value = value.toString();
        if (!silent)
            execHooks(Data.hook_value);
        return this;
    }

    getValue () => (dom.checked)? 1 : 0;

	disable() {
		setState(false);
		dom.disabled = true;
		return this;
	}

	enable() {
		setState(true);
		dom.disabled = false;
		return this;
	}

	addValidation(Function f){}

}

class Select extends _FieldBuilder<SelectField> {

    CJSElement domValue;
    String _type;

    Select ([String type = 'int']) : super (new SelectField()){
        _type = type;
		domValue = new CJSElement(new SpanElement())..setClass('ui-select');
		field.remove();
		append(domValue);
		field.appendTo(this);
        addAction((e) => _setShadowValue(), 'change');
        addAction((e) => _setShadowValue(), 'keyup');
        setClass('ui-field-select');
    }

    addOption (dynamic value, dynamic title) {
		new CJSElement(new OptionElement(data: title.toString(), value: value.toString()))..appendTo(field);
        _setShadowValue();
		if(field.dom.childNodes.length == 1)
			field.setValue(value, true);
        return this;
    }

    _setShadowValue () => domValue.dom.text = getText();

    setValue (dynamic value, [bool silent = false]) {
        field.setValue(value, silent);
        _setShadowValue();
        return this;
    }

    getValue () {
		var value = field.getValue();
        if(value == 'null')
            return null;
        return (_type == 'int' && value is String && value.isNotEmpty)? int.parse(value): value;
    }

    setOptions (List arr) {
        cleanOptions();
        arr.forEach((v) => addOption(v['k'], v['v']));
        setValue(arr.first['k'], true);
        return this;
    }

    cleanOptions () {
        field.removeChilds();
        _setShadowValue();
        return this;
    }

    getOptionsCount () => field.dom.childNodes.length;

    addOptionGroup (String group) {
		var opt = new OptGroupElement()..label = group;
		new CJSElement(opt).appendTo(field);
        return this;
    }

    getText () {
        if(field.dom.options.length > 0) {
            return (field.dom.selectedIndex > -1)?
                field.dom.options[field.dom.selectedIndex].text :
                field.dom.options.first.text;
        } else
            return '';
    }

	disable() {
		setState(false);
		field.dom.disabled = true;
        addClass('disabled');
		return this;
	}

	enable() {
		setState(true);
		field.dom.disabled = false;
        removeClass('disabled');
		return this;
	}

}

class InputDate extends Input {
    CJSElement domAction;
	gui.Pop pop;

    InputDate () : super ('date') {
        addClass('date');
        domAction = new CJSElement(new AnchorElement())
            .addAction(getDatePicker).setClass('icon i-calendar')
			.appendTo(this);
        setValue(new DateTime.now());
    }

    noAction () {
        domAction.remove();
        removeClass('date');
        return this;
    }

    fieldUpdate (value) {
        setValue(value);
        pop.close();
    }

	disable() {
		super.disable();
		domAction.hide();
	}

	enable() {
		super.enable();
		domAction.show();
	}

    getValue() {
        var d = super.getValue();
        if(d != null)
            d = d.toString();
        return d;
    }

    getValue_() => super.getValue();

    getDatePicker (e) {
		var picker = new gui.DatePicker(fieldUpdate);
		var v = getValue_();
		if (v != null)
        	picker.set(v.year, v.month, v.day);
		else
			picker.set();
		pop = new gui.Pop(picker, e);
    }

}

class InputDateRange extends _FieldBuilder<InputField> {
	FormElement<InputElementBase> field2;
	CJSElement domAction;
	gui.Pop pop;

	InputDateRange () : super (new InputField(new InputElement(), 'date')){
		addClass('ui-field-input date-range');
		field2 = new InputField(new InputElement(), 'date').appendTo(this);
		field.setStyle({'width':'70px','float':'left'});
		field2.setStyle({'width':'70px','float':'left'});
		field2.addAction((e) => focus(), 'focus');
    	field2.addAction((e) => blur(), 'blur');
		domAction = new CJSElement(new AnchorElement())
		    .addAction(getDatePicker).setClass('icon i-calendar')
			.appendTo(this);
        field.addHook(InputField.hook_validate_error, onTypeError);
        field.addHook(InputField.hook_validate_ok, onTypeOk);
        field2.addHook(InputField.hook_validate_error, onTypeError);
        field2.addHook(InputField.hook_validate_ok, onTypeOk);
    }

	focus () {
		addClass('focus');
		return this;
	}

	blur () {
		removeClass('focus');
		field.blur();
		field2.blur();
	  	return this;
	}

    getValue() {
        var d1 = field.getValue();
        var d2 = field2.getValue();
        if(d1 != null)
            d1 = d1.toString();
        if(d2 != null)
            d2 = d2.toString();
        return [d1, d2];
    }

    getValue_() => [field.getValue(), field2.getValue()];

    setValue (List value, [bool silent = false]) {
        if(value == null)
            value = [null, null];
		field.setValue(value[0], silent);
		field2.setValue(value[1], silent);
        return this;
    }

    fieldUpdate (value) {
        setValue(value);
        pop.close();
    }

    getDatePicker (e) {
        var picker = new gui.DatePickerRange(fieldUpdate);
		picker.set(getValue_());
        this.pop = new gui.Pop(picker, e);
    }

}

class InputFunction extends Input {
    CJSElement domAction;
    int valuetrue;

    InputFunction ([type]) : super(type) {
        addClass('function');
		domAction = new CJSElement(new AnchorElement())
    		.setClass('icon i-function')
			.appendTo(this);
        field.addAction((e) => setValue([null,'']), 'change');
    }

    setValue (List value, [bool silent = false]) {
        if(value == null)
            value = [null, ''];
        valuetrue = value[0];
        field.setValue(value[1], silent);
        return this;
    }

    getValue ([bool full = false]) => (full)? [valuetrue, field.getValue()] : valuetrue;

    addAction (func, [String event = 'click']) {
        if(event == 'keydown' || event == 'keyup' || event == 'change')
            field.addAction(func, event);
        else
            domAction.addAction(func, event);
        return this;
    }
}

class InputLoader extends InputFunction {
    CJSElement domList;
    List list;
    Function execute;

    InputLoader ([type]) : super(type) {
        domList = new CJSElement(new UListElement())
            .addClass('ui-list')
            .hide().appendTo(this);
        field.addAction((e) => _navAction(e, false), 'keydown');
        field.addAction(_keyAction, 'keyup');
        field.addAction(_leave, 'blur');
    }

    _getCurrent () {
        int cur_index = -1;
        int index = 0;
        for(;index < list.length; index++)
            if(list[index][1].existClass('current')) {
                cur_index = index;
                break;
            }
        return cur_index;
    }

    _moveIndex (p) {
        if(list != null && list.length == 0)
            return false;
        var cur_indx = _getCurrent();
        if(cur_indx >= 0) {
            var cur = list[cur_indx];
            cur[1].removeClass('current');
            var next_indx = cur_indx + p;
            if(next_indx > list.length - 1)
                next_indx = 0;
            if(next_indx < 0)
                next_indx = list.length - 1;
            list[next_indx][1].addClass('current');
        } else {
            list[0][1].addClass('current');
        }
        return true;
    }

    _navAction (KeyEvent e, bool no_exec) {
        var k = new utils.EventValidator(e);
        if(k.isKeyDown()) {
            e.stopPropagation();
            e.preventDefault();
            if(!no_exec)
                _moveIndex(1);
            return true;
        } else if(k.isKeyUp()) {
            e.stopPropagation();
            e.preventDefault();
            if(!no_exec)
                _moveIndex(-1);
            return true;
        } else if(k.isKeyEnter()) {
            e.stopPropagation();
            e.preventDefault();
            if(list != null) {
                var cur_indx = (list.length == 1) ? 0 : _getCurrent();
                if (cur_indx >= 0) {
                    var cur = list[cur_indx];
                    setValue([cur[0]['k'], cur[0]['v']]);
                    _hideList();
                }
            }
            return true;
        }
        return false;
    }

    _keyAction (e) {
        if(!_navAction(e, true)) {
            _hideList();
            _proceedLoad(field.getValue());
        }
    }

    _renderList (List o) {
        domList.removeChilds();
        list = new List();
        var string = field.getValue();
        o.forEach((el) {
            var e = new CJSElement(new LIElement()).addAction((e) => setValue([el['k'], el['v']]), 'mousedown');
            var p = '(${string})';
            e.setHtml(el['v'].replaceAllMapped(new RegExp(p, caseSensitive: false), (m) => '<strong>${m[0]}</strong>'));
            domList.append(e);
            list.add([el, e]);
        });
        _showList();
    }

    _showList() {
        var width = getWidth(),
            shift = getHeightInnerShift() / 2,
            left = getPosition();
        domList.show();
        var pos = domList.getPosition();
        domList.appendTo(document.body)
        .setStyle({
            'position':'absolute',
            'top':'${pos['top'] + shift}px',
            'left':'${left['left']}px',
            'width': '${width}px'});
    }

    _hideList() {
        domList.appendTo(this)
        .setStyle({
            'position':'relative',
            'top':'0px',
            'left':'0px'});
        domList.hide();
    }

    _leave (e) {
        _hideList();
        if(getValue() == null)
            setValue([null, '']);
    }

    _proceedLoad (string) {
        if(string == '') {
            _hideList();
        } else {
            addClass('loading');
            execute(this, string);
        }
    }

    onLoad (data) {
        removeClass('loading');
        _renderList(data);
    }

}

abstract class _Lang extends DataElement<DivElement> {

    CJSElement<ImageElement> flag;
	List langs = new List();
    Map flags = new Map();
    static Map _static = {
		'objects': new List(),
        'current': 0
	};

    _Lang (List lang) : super (new DivElement()){
        _static['objects'].add(this);
		setStyle({'position':'relative'});
        var inner = new CJSElement(new DivElement()).setStyle({'overflow':'hidden'}).appendTo(this);
        flag = new CJSElement(new ImageElement())
            .setStyle({'position':'absolute', 'top':'4px', 'right':'4px', 'opacity':'0.5', 'cursor':'pointer'})
            .appendTo(this);
		flag
            .addAction(toggleLang, 'click')
            .addAction((e) => flag.setStyle({'opacity':'1'}), 'mouseover')
            .addAction((e) => flag.setStyle({'opacity':'0.5'}), 'mouseout');
        var i = 0;
		lang.forEach((l) {
			var language_id = l['language_id'];
	    	langs.add(_builder().setName(language_id.toString()).setValue('').appendTo(inner));
	    	flags[i.toString()] = l['code'];
			i++;
		});
		showSingleValue(0);
    }

    DataElement _builder ();

    getFields () => langs;

    toggleLang (e) {
		_static['current'] ++;
        if (_static['current'] == langs.length)
        	_static['current'] = 0;
        _static['objects'].forEach((l) => l.showSingleValue(_static['current']));
    }

    setSingleValue (value, [silent]) {
        langs[_static['current']].setValue(value, silent);
        showSingleValue(_static['current']);
        return this;
    }

    showSingleValue (key) {
        hideAll();
        langs[key].show();
		flag.dom.src = 'packages/cl_base/images/ui/flags/'+flags[key.toString()]+'.png';
        return this;
    }

    getValue ([key]) {
        if (key != null)
            return langs[key].getValue();
        var value = {};
		langs.forEach((v) => value[v.getName()] = v.getValue());
		return value;
    }

    setValue (Map valueObj, [bool silent = false]) {
		langs.forEach((v) => v.setValue('', silent));
        if(valueObj is Map)
            valueObj.forEach((k, v) => langs.firstWhere((l) => l.getName() == k).setValue(v, silent));
        return this;
    }

    disable () {
		langs.forEach((v) => v.disable());
        return this;
    }

    enable () {
		langs.forEach((v) => v.enable());
        return this;
    }

    setClass (String clas) {
		langs.forEach((v) => v.setClass(clas));
        return this;
    }

    hideAll () {
		langs.forEach((v) => v.hide());
        return this;
    }

    addHook (hook, func) {
		langs.forEach((v) => v.addHook(hook, func));
		return this;
    }
}

class LangInput extends _Lang {

    LangInput(List lang) : super(lang);

    _builder() => new Input();

}

class LangEditor extends _Lang {

    app.Application app;

    LangEditor(this.app, List lang) : super(lang);

    _builder() => new Editor(app);

}

class LangArea extends _Lang {

	LangArea(List lang) : super(lang);

    _builder() => new TextArea();

}

class Form extends ElementCollection {

	_toOBJ () {
	    var o = {};
	    for (var i=0, l=indexOfElements.length;i<l;i++) {
	        var el = indexOfElements[i];
	        if (el._send)
	            o[el.getName()] = el.getValue();
	    }
	    return o;
	}

	toOBJ ([bool context = false]) {
		if(!context)
			return _toOBJ();
	    var o = {};
	    for (var i=0, l=indexOfElements.length;i<l;i++) {
			var el = indexOfElements[i];
	        if (!el._send)
	            continue;
	        var key = el.getName(),
	        	value = el.getValue();
			if(value == null)
          		continue;
	        var context = el.getContext();
	        if (context != null) {
	            if (o[context] == null)
	                o[context] = {};
	            o[context][key] = value;
	        }
	        else
	            o[key] = value;
	    }
	    return o;
	}

	getRequired () {
	    var req = [];
		indexOfElements.forEach((el) => (!el.isReady())? req.add(el) : null);
	    return req;
	}

	setElementData (String name, dynamic value) {
	    var el = getElement(name);
	    if (el is Data)
	        el.setValue(value, true);
	    return this;
	}

	setData (Map o) {
		o.forEach((k, v) => setElementData(k, v));
	    return this;
	}

	clear () {
        indexOfElements.forEach((el) => (el is Data)? el.setValue(null, true) : null);
		return this;
	}

    disable () {
		indexOfElements.forEach((el) => (el is DataElement)? el.disable() : null);
        return this;
    }
}

class Paginator extends DataElement {
	int _page = 1;
	int _limit = 50;
	int _total = 0;

	action.Button contr_p, contr_n, contr_l, contr_f;
	Input contr_i;
	Select contr_c;
	Text contr_t;

	Paginator () : super (new DivElement()) {
		setClass('ui-paginator');
		var margin = '5px 0px 0px 5px';
        contr_f = new action.Button().setIcon('controls-first').addAction(firstPage, 'click').setStyle({'margin':margin});
        contr_p = new action.Button().setIcon('controls-previous','5px 50%').addAction(previousPage, 'click').setStyle({'margin':margin});
        contr_n = new action.Button().setIcon('controls-next','8px 50%').addAction(nextPage, 'click').setStyle({'margin':margin});
        contr_l = new action.Button().setIcon('controls-last').addAction(lastPage, 'click').setStyle({'margin':margin});

        contr_i = new Input('int')
            .setValue(1, true).setWidth(40)
            .setStyle({'margin':margin})
            .addAction(curPage, 'change');

        contr_c = new Select()
            .setStyle({'margin':margin})
            .addOption(50, 50)
            .addOption(100, 100)
            .addOption(500, 500)
            .addOption(1000, 1000)
            .addOption(null, INTL.All())
            .addAction(firstPage, 'change');

        contr_t = new Text()
            .setStyle({
                'display':'block',
                'float':'left',
                'padding':'5px 0px',
                'margin':margin
            });

        setStyle({'float':'left'});
        append(contr_f);
        append(contr_p);
        append(contr_i);
        append(contr_n);
        append(contr_l);
        append(contr_c);
        append(contr_t);
    }

    firstPage ([e]) {
        setPage(1);
    }

    previousPage ([e]) {
        setPage(_page - 1);
    }

    nextPage ([e]) {
        setPage(_page + 1);
    }

    lastPage ([e]) {
        if(_limit != null)
            setPage((_total/_limit).ceil());
    }

    curPage ([e]) {
        setPage(contr_i.getValue());
    }

    setPage ([int page, bool silent = false]) {
        page = (page == null)? _page : page;
        var limit = contr_c.getValue();
        var pages = (limit != null)? (_total/limit).ceil() : 1;
        page = Math.max(Math.min(page, pages), 1);
        contr_i.setValue(page);
        var right_state = (limit != null)? ((page*limit < _total) ? true : false) : false;
        contr_l.setState(right_state);
        contr_n.setState(right_state);
        var left_state = (limit != null)? ((page == 1) ? false : true) : false;
        contr_f.setState(left_state);
        contr_p.setState(left_state);
        if (_page == page && _limit == limit)
            return;
        _page = page;
        _limit = limit;
        if (!silent)
            execHooks(Data.hook_value);
    }

    setValue (int total, [bool silent = false]) {
        _total = total;
        var from = (_limit != null)? (_page - 1) * _limit + 1 : 0;
        from = (from < 0)? 0 : from;
        var to = (_limit != null)? _page * _limit : _total;
        to = (to > _total)? _total : to;
        contr_t.setValue(INTL.pages(from, to, _total));
        setPage(null, silent);
        return this;
    }

    getValue () => {'page': _page, 'limit': _limit};

}

final NodeValidatorBuilder _htmlValidator = new NodeValidatorBuilder.common()
    ..allowInlineStyles();

class Editor extends DataElement {
    app.Application ap;
	CJSElement<DivElement> frame;
    TextArea field;
    CJSElement head, body, footer, path;
	utils.Draggable drag;

    action.Menu menu;
    Map menu_els;

    CJSElement _parent_dom;
    int _b_height;
    bool _fullscreen = false;

	CJSElement _fixover;
	utils.Point _res_pos;
	int _res;

    Editor (this.ap) : super(new DivElement()) {
		setClass('ui-editor');
        _createHTML();
        _initMenu();
        _createMenu();
    }

    _initMenu () {
        menu_els = {
            'arrow-undo':           ['Undo', 'undo'],
            'arrow-redo':           ['Redo', 'redo'],
            //'cut':                  ['Cut', 'cut'],
            //'page-copy':            ['Copy', 'copy'],
            //'page-paste':           ['Paste', 'paste'],
            'text-bold':            ['Bold', 'bold'],
            'text-italic':          ['Italic', 'italic'],
            'text-underline':       ['Underline', 'underline'],
            'text-strikethrough':   ['Strikethrough', 'strikethrough'],
            'text-subscript':       ['Subscript', 'subscript'],
            'text-superscript':     ['Superscript', 'superscript'],
           /* 'font':                 ['Font', 'fontname', [
                                            ['Font',''],
                                            ['Arial','arial,helvetica,sans-serif'],
                                            ['Verdana','verdana,helvetica,sans-serif'],
                                            ['Helvetica','helvetica,sans-serif'],
                                            ['Lucida Sans Unicode','lucida sans unicode,lucida grande,sans-serif'],
                                            ['Tahoma','tahoma,geneva,sans-serif'],
                                            ['Courier New','courier new,courier,monospace'],
                                            ['Times New Roman','times new roman,times,serif'],
                                            ['Comic Sans MS','comic sans ms,cursive'],
                                            ['Georgia','georgia,serif']
                                        ]
                                    ],*/
            //'fontsize':             ['Font Size', 'fontsize', [['Font Size',''],[1],[2],[3],[4],[5],[6],[7]]],
            //'formatblock':          ['Format Block', 'formatblock', [['Style',''],['Paragraph','<p>'],['Header 1','<h1>'],['Header 2','<h2>'],['Header 3','<h3>'],['Header 4','<h4>'],['Header 5','<h5>'],['Header 6','<h6>']]],
            'text-list-numbers':    ['Insert Ordered List', 'insertorderedlist'],
            'text-list-bullets':    ['Insert Unordered List', 'insertunorderedlist'],
            'text-indent-remove':   ['Outdent', 'outdent'],
            'text-indent':          ['Indent', 'indent'],
            'text-align-left':      ['Left Align', 'justifyleft'],
            'text-align-center':    ['Center Align', 'justifycenter'],
            'text-align-right':     ['Right Align', 'justifyright'],
            'text-align-justify':   ['Block Justify', 'justifyfull'],
            //'text-horizontalrule':  ['Insert Horizontal Rule', 'inserthorizontalrule'],
            'image':                ['Insert Image', (e) => insertImage(e, 'insertimage')],
            'link-add':             ['Insert Hyperlink', (e) => insertUrl(e, 'createlink')],
            //'link-break':           ['Remove Hyperlink', 'unlink'],
            'clear':         ['Remove Formatting', 'removeformat'],
            'printer':              ['Print', 'print'],
            'fullscreen':           ['Fullscreen', fullScreen]
        };
    }

    _createHTML () {
        head = new CJSElement(new DivElement()).setClass('ui-editor-header').appendTo(this);
        body = new CJSElement(new DivElement()).setClass('ui-editor-body').appendTo(this);
        footer = new CJSElement(new DivElement()).setClass('ui-editor-footer').addClass('ui-editor-footer-resize').appendTo(this);

		drag = new utils.Draggable(footer, 'editor')
        	..observer.addHook('start', (list) => _resizeBefore(list[0]))
        	..observer.addHook('on', (list) => _resizeOn(list[0]))
        	..observer.addHook('stop', (list) => _resizeAfter(list[0]));

        field = new TextArea().hide().setStyle({'width':'100%'}).appendTo(body);
        path = new CJSElement(new SpanElement()).setStyle({'float':'left','white-space':'nowrap','padding':'8px 0px 0px 8px'}).appendTo(footer);
        frame = new CJSElement(new DivElement())
				.setClass('iframe')
				.addAction(_getPath, 'mousedown').appendTo(body)
				.addAction(_onBlur, 'keyup');
		frame.dom.contentEditable = 'true';
    }

    _createMenu () {
        menu = new action.Menu(head);
		menu_els.forEach((k, cur) {
			var a = null;
			if(cur.length == 2) {
				a = new action.Button().setIcon(k);
				Function func = (cur[1] is String)? (e) => _exec(cur[1]) : cur[1];
				a.addAction(func, 'click');
				a.domAction.dom.setAttribute('unselectable', 'on');
			} else {
				a = new Select();
		      	cur[2].forEach((o) {
		      		var t = o[0];
		      		var v = o[1]? o[1] : o[0];
		      		a.addOption(v,t);
		      	});
		      	a.addAction((e) => _exec(cur[1], a.getValue()), 'change');
			}
			if(a != null)
				menu.add(a);
		});
        new action.Button()
            .setIcon('source')
            .setStyle({'float':'right'})
            .addAction(_toggleSource, 'click')
			.appendTo(footer);
    }

    _resizeBefore (e) {
        e.stopPropagation();
        _fixover = new CJSElement(new DivElement())
            .setStyle({
                'position':'absolute',
                'width':'100%',
                'height':'100%',
                'z-index':'1',
                'top':'0px',
                'left':'0px'
            }).appendTo(body);
        _res_pos = new utils.Point(e.page.x, e.page.y);
        _res = body.getHeight();
    }

    _resizeOn (e) {
        e.stopPropagation();
        var pos = new utils.Point(e.page.x, e.page.y);
        var diff_pos = pos - _res_pos;
        body.setStyle({'height':(_res + diff_pos.y).toString() + 'px'});
    }

    _resizeAfter (e) {
        _fixover.remove();
    }

    setValue (dynamic value, [bool silent = false]) {
        field.setValue(value, silent);
        _setIframeValue(getValue());
        return this;
    }

    getValue () {
        return field.getValue();
    }

    fullScreen (e) {
        if(_fullscreen) {
            setStyle({
                'position':'relative',
                'width':'auto',
                'top':'auto',
                'left':'auto',
                'zIndex':'auto'
            });
            body.setHeight(_b_height);
            _parent_dom.append(this);
            _fullscreen = false;
            footer.addClass('ui-editor-footer-resize');
            drag.enable = true;
        } else {
            _parent_dom = new CJSElement(dom.parentNode);
            var doc = new CJSElement(document.body).append(setStyle({
                'position':'absolute',
                'width':'100%',
                'top':'0px',
                'left':'0px',
                'z-index':'999998'
            }).dom);
            _b_height = body.getHeight();
            fillParent();
            _fullscreen = true;
        }
    }

    insertImage (e, cmd) {
        var range = window.getSelection().getRangeAt(0);
        new FileManager(ap, (path) {
            window.getSelection()
                ..removeAllRanges()
                ..addRange(range);
            _exec(cmd, path);
        });
    }

    insertUrl (e, cmd) {
        var sel = window.getSelection();
        if(sel.baseOffset == 0)
            return;
        var range = window.getSelection().getRangeAt(0);
        app.Win win = ap.winmanager.loadBoundWin({'title':'URL'});
        var input = new Input().setStyle({'width':'100%'});
        var data = new ContainerData().setStyle({'padding':'3px'});
        var option = new ContainerOption();
        var ok = new action.Button()
            .setTitle('ОК')
            .setStyle({'float':'right'})
            .addAction((e){
                win.close();
                window.getSelection()
                    ..removeAllRanges()
                    ..addRange(range);
                _exec(cmd, input.getValue());
            },'click');
        new action.Menu(option).add(ok);

        data.append(input);

        win.getContent()
            ..addRow(data)
            ..addRow(option);
        win.render(350, 100);
        input.focus();
    }

    /*getExecutableElement () {
		return frame.dom;
    }

    setEditable (e) {
        var ifr = getExecutableElement();
        ifr.contentEditable = "true";
        new CJSElement(ifr).addAction(getPath, 'mousedown');
        //if(ifr.body)
			new CJSElement(ifr).addAction(_onBlur, 'keyup');
        setIframeValue(getValue());
        return this;
    }*/

    _exec (cmd, [value]) {
        frame.dom.ownerDocument.execCommand(cmd, false, value);
        if(cmd != 'print')
            field.setValue(frame.dom.innerHtml);
		focus();
    }

    _getPath (e) {
        var cur = e.target;
        var arr = [];
        while (cur.contentEditable != 'true') {
            arr.add(cur.nodeName);
            cur = cur.parentNode;
        }
        path.dom.text = arr.reversed.join(' ');
    }

    _setIframeValue (value) {
    	frame.dom.innerHtml = value.toString();
        return this;
    }

    _onBlur (e) {
		var fixed = _fixHtml(frame.dom.innerHtml);
        if (field.getValue() != fixed)
            field.setValue(fixed);
        removeClass('ui-editor-error');
    }

    setRequired (required) {
		super.setRequired(required);
        if(required)
            addHook(Data.hook_require, () => addClass('ui-editor-error'));
        return this;
    }

    focus () {
        frame.dom.focus();
        return this;
    }

    fillParent () {
        footer.removeClass('ui-editor-footer-resize');
        drag.enable = false;
        var close = false;
        if(getStyle('display') == 'none') {
            show();
            close = true;
        }
		var parent = new CJSElement(dom.parentNode);
        body.setHeight(parent.getHeight() - head.getHeight() - footer.getHeight() - parent.getHeightInnerShift());
        if(close) {
            hide();
        }
    }

    _fixHtml (String html) {
		return html
            .replaceAll(new RegExp(r' class="apple-style-span', multiLine: true, caseSensitive: false),'')
            .replaceAll(new RegExp(r'<span style="">', multiLine: true, caseSensitive: false),'')
            .replaceAll(new RegExp(r'<br>', multiLine: true, caseSensitive: false), '<br />')
            .replaceAll(new RegExp(r'<br ?\/?>$', multiLine: true, caseSensitive: false), '')
            .replaceAll(new RegExp(r'^<br ?\/?>', multiLine: true, caseSensitive: false), '')
			.replaceAllMapped(new RegExp(r'<span class="apple-style-span">(.*)<\/span>', multiLine: true, caseSensitive: false), (m) => '${m[1]}')
            .replaceAllMapped(new RegExp(r'(<img [^>]+[^\/])>', multiLine: true, caseSensitive: false), (m) => '${m[1]} />')
			.replaceAllMapped(new RegExp(r'<b\b[^>]*>(.*?)<\/b[^>]*>', multiLine: true, caseSensitive: false), (m) => '<strong>${m[1]}</strong>')
			.replaceAllMapped(new RegExp(r'<i\b[^>]*>(.*?)<\/i[^>]*>', multiLine: true, caseSensitive: false), (m) => '<em>${m[1]}</em>')
			.replaceAllMapped(new RegExp(r'<u\b[^>]*>(.*?)<\/u[^>]*>', multiLine: true, caseSensitive: false), (m) => '<span style="text-decoration:underline">${m[1]}</span>')
            .replaceAllMapped(new RegExp(r'<(b|strong|em|i|u) style="font-weight: normal;?">(.*)<\/(b|strong|em|i|u)>', multiLine: true, caseSensitive: false), (m) => '${m[2]}')
			.replaceAllMapped(new RegExp(r'<(b|strong|em|i|u) style="(.*)">(.*)<\/(bs|strong|em|i|u)>', multiLine: true, caseSensitive: false), (m) => '<span style="${m[2]}"><${m[4]}>${m[3]}</${m[4]}></span>')
			.replaceAllMapped(new RegExp(r'<span style="font-weight: normal;?">(.*)<\/span>', multiLine: true, caseSensitive: false), (m) => '${m[1]}')
			.replaceAllMapped(new RegExp(r'<span style="font-style: italic;?">(.*)<\/span>', multiLine: true, caseSensitive: false), (m) => '<em>${m[1]}</em>')
			.replaceAllMapped(new RegExp(r'<span style="font-weight: bold;?">(.*)<\/span>|<b\b[^>]*>(.*?)<\/b[^>]*>', multiLine: true, caseSensitive: false), (m) => '<strong>${m[1]}</strong>')
			.replaceAllMapped(new RegExp(r'<font face="(.*)">(.*)<\/font>', multiLine: true, caseSensitive: false), (m) => '<span style="font-family:${m[1]}">${m[2]}</span>');
    }

    _toggleSource (e) {
        if (frame.getStyle('display') == 'none') {
            frame.show();
            frame.dom.setInnerHtml(field.hide().getValue(), validator:_htmlValidator);
            //frame.dom.innerHtml = field.hide().getValue();
            path.show();
            menu.indexOfElements.forEach((b) => b.setState(true));
        } else {
            frame.hide();
			var fixed = _fixHtml(frame.dom.innerHtml);
            field.setValue(fixed, true).show();
            path.hide();
            menu.initButtons([]);
        }
	}

    addHook (hook, func) {
        if(hook == Data.hook_require)
            super.addHook(hook, func);
        else
            field.addHook(hook, func);
        return this;
    }
}


class Tag extends DataElement {

    List forms = new List();

    Tag () : super (new DivElement()) {
        setClass('ui-tag');
    }

    addValue (List value, [bool silent = false]) {
        var form = new Form();
        form.add(new Data().setName('value').setValue(value[0], silent));
        forms.add(form);
        var tag = new CJSElement(new SpanElement())
            .setClass('ui-field-tag')
            .appendTo(this);
        new CJSElement(new SpanElement())
            .setClass('ui-field-tag-inner')
            .setText(value[1])
            .appendTo(tag);
        new CJSElement(new AnchorElement())
            .setClass('icon i-tag-remove')
            .addAction((e) => _remove(form,tag))
            .appendTo(tag);
        return this;
    }

    setValue (List value, [bool silent = false]) {
        for(int i=0, l = forms.length; i<l; i++)
            if(forms[i]['value'].getValue() == value[0])
                return this;
        return addValue(value, silent);
    }

    getValue () {
        var a = [];
        forms.forEach((f) => a.add(f.toOBJ()));
        return a;
    }

    _remove (form, tag) {
        var temp = [];
        forms.forEach((f) {
            if(f != form)
                temp.add(f);
        });
        forms = temp;
        tag.remove();
    }
}

class FileManager {
    app.Application ap;
    app.WinApp wapi;
    Map html;
    var w = {'title':INTL.File_manager(), 'icon':'group', 'width':1000, 'height':570, 'type':'bound'};
    Function callback;
    String main = 'upload';
    gui.TreeBuilder tree;
    var current;
    var current_file;
    action.Menu menuTop;
    action.Menu menu;
    List list;

    FileManager(this.ap, this.callback) {
        wapi = new app.WinApp(ap);
        initInterface();
        initTree();
        wapi.render();
        initLeftMenuTop();
        initRightMenuTop();
        wapi.initLayout();
    }

    initInterface () {
        html = {'left_options_top': new ContainerOption(),
            'left_inner': new ContainerDataLight(),
            'right_options_top' :new ContainerOption(),
            'right_inner': new ContainerData().addAction(renderView,'scroll')};

        var col1 = new Container().setWidth(150)
            ..addRow(html['left_options_top'])
            ..addRow(html['left_inner']);
        var col2 = new Container()..auto = true
            ..addRow(html['right_options_top'])
            ..addRow(html['right_inner']);

        wapi.load(w, this);

        wapi.win.getContent()
            ..addCol(col1)
            ..addSlider()
            ..addCol(col2);
    }

    renderView () {
        if(list.length > 0) {
            var first = list.first;
            var dim = first['cont'].getDimensions(),
                box_width = dim['width'] + first['cont'].getWidthOuterShift(),
                box_height = dim['height'] + first['cont'].getHeightOuterShift(),
                view_dim = html['right_inner'].getDimensions(),
                count_left = (view_dim['width']/box_width).round(),
                count_top = (view_dim['height']/box_height).round(),
                scroll_top = html['right_inner'].dom.scrollTop,
                shift = ((scroll_top/dim['height'])*count_left).round(),
                start = 0 + shift,
                stop = count_top*count_left + shift;
            int i = 0;
            list.forEach((thumb) {
                if(!thumb['rendered'] && i>=start && i<stop) {
                    thumb['cont'].setStyle({'background-image':'url(media/image${dim['width']}x${dim['height']}/${Uri.encodeComponent(thumb['file'])})'});
                    thumb['rendered'] = true;
                    i++;
                }
            });
        }
    }

    initTree () {
        tree = new gui.TreeBuilder({
            'value':'[ '+INTL.Folders()+' ]',
            'id':main,
            'icons': {'folder':'group'},
            'action': clickedFolder,
            'load': (renderer, item) {
                ap.serverCall('/directory/list', {'dirname': item.id},  html['left_inner'])
                .then((data) => renderer(item, data));
            }
        });
        html['left_inner'].append(tree);
        tree.loadTree(tree.main);
    }

    clickedFolder (folder) {
        if(folder.id != main) {
            menuTop.initButtons(['folderadd','folderedit','foldermove','folderdelete']);
            menu.initButtons(['fileadd']);
        } else {
            menuTop.initButtons(['folderadd']);
            menu.initButtons(['fileadd']);
        }
        current = folder;
        current_file = null;
        list = [];
        ap.serverCall('/file/list', {'dirname':current.id}, html['right_inner'])
        .then((data) {
            html['right_inner'].removeChilds();
            data.forEach((f) {
                var c = new CJSElement(new DivElement())
                .addClass('ui-filemanager-image')
                .appendTo(html['right_inner']);
                var o = {
                    'cont':c,
                    'file':f,
                    'rendered': false
                };
                list.add(o);
                c.addAction((e) => clickedFile(o), 'click')
                .addAction((e) => callback('media/${o['file']}'), 'dblclick');
            });
            renderView();
        });
    }

    clickedFile (file) {
        if(current_file)
            current_file['cont'].removeClass('ui-file-clicked');
        current_file = file;
        file['cont'].addClass('ui-file-clicked');
        menu.initButtons(['fileadd','filedelete']);
    }

    initLeftMenuTop () {
        menuTop = new action.Menu(html['left_options_top']);
        menuTop.add(new action.Button().setName('folderadd').setState(false).setIcon('folder-add').addAction(folderAdd));
        menuTop.add(new action.Button().setName('folderedit').setState(false).setIcon('folder-edit').addAction(folderEdit));
        menuTop.add(new action.Button().setName('foldermove').setState(false).setIcon('folder-go').addAction(folderMove));
        menuTop.add(new action.Button().setName('folderdelete').setState(false).setIcon('folder-delete').addAction(folderDelete));
    }

    initRightMenuTop () {
        menu = new action.Menu(this.html['right_options_top']);
        var uploader = new action.FileUploader().setName('fileadd').setTitle(INTL.Add_file()).setState(false).setIcon('add');
        uploader.observer.addHook(action.FileUploader.hook_loaded, (files) {
            clickedFolder(current);
            return true;
        });
        menu.add(uploader.addAction((e) => fileAdd(uploader)));
        menu.add(new action.Button().setName('filedelete').setTitle(INTL.Delete_file()).setState(false).setIcon('delete').addAction(fileDelete));
    }

    folderAdd (e) {
        menuTop.initButtons([]);
        gui.Tree parent = current;
        var newfolder = parent.add({'value':'','type':'directory'});
        parent.initialize(parent.level, parent.isLast, parent.leftSide);
        parent.isLoading = false;
        parent.loadChilds = false;
        parent.isOpen = false;
        parent.operateNode();
        var input = new Input();
        var called = false;
        var addCatRefresh = (KeyEvent e) {
            if(e is FocusEvent || e.keyCode == 13 || e.keyCode == 27 || e.type=='blur') {
                if(called)
                    return;
                called = true;
                ap.serverCall('/directory/add', {'parent': parent.id, 'dirname': input.getValue()}, html['left_inner'])
                .then((data) {
                    parent.treeBuilder.refreshTree(parent);
                });
            }
        };
        input.setValue('New folder')
            .appendTo(newfolder.domValue)
            .focus()
            .select()
            .addAction(addCatRefresh,'blur')
            .addAction(addCatRefresh,'keydown');
    }

    folderDelete (e) {
        ap.serverCall('/directory/delete', {'dirname':current.id}, html['left_inner'])
        .then((data) {
            current.treeBuilder.refreshTree(current.parent);
        });
    }

    folderEdit (e) {
        var field = current.domValue;
        var input = new Input();
        new CJSElement(field).setHtml('').removeClass('active').append(input);
        input.setValue(current.value).focus().select();
        var called = false;
        var addCatRefresh = (KeyEvent e) {
            if(e is KeyboardEvent && e.keyCode == 27) {
                field.innerHtml = current.value;
            } if(e.type == 'blur' || (e is KeyboardEvent && e.keyCode == 13)) {
                if(called)
                    return;
                called = true;
                ap.serverCall('/directory/edit', {'dirname': current.id, 'name': current.parent.id + '/' + input.getValue()}, null)
                .then((data){
                    current.treeBuilder.refreshTree(current.parent);
                    menuTop.initButtons(['folderadd', 'folderedit', 'foldermove', 'folderdelete']);
                });
            }
        };
        input.addAction(addCatRefresh,'blur')
            .addAction(addCatRefresh,'keydown');
    }

    folderMove (e) {
        var html = {'inner': new ContainerDataLight()};
        wapi.load({'title': INTL.Move_to(), 'icon': 'group', 'type':'bound'}, this);
        wapi.win.getContent().addRow(html['inner']);
        var container = new CJSElement(new DivElement()).setClass('ui-tree-cont');
        html['inner'].dom.innerHtml = '';
        html['inner'].append(container);
        var moveTo = (folder) {
            if((current.id != folder.id && current.parent.id != folder.id))
                ap.serverCall('/directory/move', {'dirname': this.current.id, 'to':'${folder.id}/${current.value}'}, null)
                .then((data) {
                    current.treeBuilder.refreshTree(current.treeBuilder.main);
                    wapi.win.close();
                });
        };
        var o = {
            'value':'[ '+INTL.Folders()+' ]',
            'id':main,
            'icons': {'folder':'group'},
            'action': moveTo,
            'load': (renderer,item) {
                ap.serverCall('/directory/list', {'dirname': item.id}, null)
                .then((data) => renderer(item,data));
            }
        };
        tree = new gui.TreeBuilder(o);
        container.append(tree);
        tree.main.openChilds();
        wapi.win.render(300, 350);
    }

    fileAdd (action.FileUploader uploader) {
        uploader.setUpload('upload?path=' + Uri.encodeComponent('media/${current.id}'));
    }

    fileDelete (e) {
        ap.serverCall('/file/delete', {'file' : current_file['file']}, html['right_inner'])
        .then((data) {
            current_file['cont'].remove();
            current_file = null;
        });
    }
}