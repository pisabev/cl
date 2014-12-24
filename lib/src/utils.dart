part of utils;

class Observer {
    Map _hook;

    Observer () {
        _hook = new Map<String, Queue>();
    }

    addHook (String scope, dynamic func, [bool first = false]) {
        if(_hook[scope] == null)
            _hook[scope] = new Queue();
        if(func is Queue) {
            _hook[scope].addAll(func);
        } else if (func is Function) {
            if(first)
                _hook[scope].addFirst(func);
            else
                _hook[scope].add(func);
        }
    }

    getHook ([String scope]) => scope != null? _hook[scope] : _hook;

    Future<bool> execHooks (String scope, [dynamic object]) {
        Completer completer = new Completer();
        if(_hook[scope] is Queue) {
            Iterator iterator = _hook[scope].iterator;
            bool ret = true;
            Future.doWhile(() {
                if (!iterator.moveNext()) return false;
                return new Future.sync(() => ret = (object != null)? iterator.current(object) : iterator.current());
            }).then((_) => completer.complete(ret));
        } else {
            completer.complete(true);
        }
        return completer.future;
    }

    removeHook (String scope, [Function func]) {
        if(func is Function) {
            if(_hook[scope].contains(func))
                _hook[scope].remove(func);
        } else {
            _hook[scope] = new Queue();
        }
    }
}

class Drag {
    CJSElement object;
    String _namespace;

    Function _start, _on, _end = (_) {};

    MouseEvent _init_e;

    int dx, dy = 0;

    bool enable = true;

    Drag(this.object, [String this._namespace = 'drag']) {
        object.addAction(drag, 'mousedown' + '.' + _namespace);
    }

    start(start) => _start = start;

    on(Function on) => _on = on;

    end(Function stop) => _end = stop;

    drag (MouseEvent e) {
        if(!enable)
            return;
        _init_e = e;
        _start(e);
        var document_move = document.onMouseMove.listen((e) {
            dx = e.client.x - _init_e.client.x;
            dy = e.client.y - _init_e.client.y;
            _on(e);
        });
        var document_up = null;
        document_up = document.onMouseUp.listen((e) {
            document_move.cancel();
            document_up.cancel();
            _end(e);
        });
    }
}

class EventValidator {
    KeyboardEvent event;

    EventValidator (this.event);

    isBasic () {
        var event = this.event,
            code = event.which;
        if(event.ctrlKey || (code > 7 && code < 47) || (code > 90 && code < 94) || (code > 111 && code < 146))
            return true;
        return false;
    }

    isNum () {
        var event = this.event,
            code = event.which;
        if(((!event.shiftKey && (code > 47 && code < 58)) || (code > 95 && code < 106)))
            return true;
        return false;
    }

    isPoint () {
        var event = this.event,
            code = event.which;
        if(((!event.shiftKey && code == 190) || code == 110))
            return true;
        return false;
    }

    isMinus () {
        var event = this.event,
            code = event.which;
        if(((!event.shiftKey && code == 189) || code == 109))
            return true;
        return false;
    }

    isPlus () {
        var event = this.event,
            code = event.which;
        if(((event.shiftKey && code == 187) || code == 107))
            return true;
        return false;
    }

    isSlash () {
        var event = this.event,
            code = event.which;
        if(!event.shiftKey && (code == 111 || code == 191))
            return true;
        return false;
    }

    isColon () {
        var event = this.event,
            code = event.which;
        if (code && new String.fromCharCode(code) == ':')
            return true;
        return false;
    }

    isKeyDown () {
        var event = this.event,
            code = event.which;
        if(code == 40)
            return true;
        return false;
    }

    isKeyUp () {
        var event = this.event,
            code = event.which;
        if(code == 38)
            return true;
        return false;
    }

    isKeyEnter () {
        var event = this.event,
            code = event.which;
        if(code == 13)
            return true;
        return false;
    }

    isESC () {
        var event = this.event,
        code = event.which;
        if(code == 27)
            return true;
        return false;
    }

}

class KeyAction {

    static String CTRL_S = 'ctrl+s';

    static final Map _combos = {
        'ctrl+s': (KeyboardEvent e) => (e.ctrlKey && e.which == 83)? true : false
    };

    String combo;
    Function action;

    KeyAction(this.combo, this.action);

    run(e) {
        if(_combos[combo](e)) {
            e.preventDefault();
            action();
        }
    }

}

Map keybord_combo = {
    'ctrl+s': (KeyboardEvent e) => (e.ctrlKey && e.which == 83)? true : false
};

class Calendar {

    static bool firstDayMonday = true;

    static List label_months = new DateFormat().dateSymbols.MONTHS;

    static List label_days = new DateFormat().dateSymbols.WEEKDAYS;

    static List ranges = [
        {'title': INTL.Today(), 'method': getTodayRange},
        {'title': INTL.Yesterday(), 'method': getYesterdayRange},
        {'title': INTL.One_week_back(), 'method': getWeeksBackRange},
        {'title': INTL.This_week(), 'method': getThisWeekRange},
        {'title': INTL.Last_week(), 'method': getLastWeekRange},
        {'title': INTL.One_month_back(), 'method': getMonthsBackRange},
        {'title': INTL.This_month(), 'method': getThisMonthRange},
        {'title': INTL.Last_month(), 'method': getLastMonthRange},
        {'title': INTL.One_year_back(), 'method': getYearsBackRange},
        {'title': INTL.This_year(), 'method': getThisYearRange},
        {'title': INTL.Last_year(), 'method': getLastYearRange},
        {'title': INTL.All(), 'method': getAllRange}
	];

    static UTCDifference(DateTime date1, DateTime date2) =>
        new DateTime.utc(date1.year, date1.month, date1.day)
        .difference(new DateTime.utc(date2.year, date2.month, date2.day));

    static UTCAdd(DateTime date, Duration dur) {
        DateTime utc = new DateTime.utc(date.year, date.month, date.day).add(dur);
        return new DateTime(utc.year, utc.month, utc.day);
    }

    static weekDayFirst() => firstDayMonday? 1 : 0;

    static weekDayLast() => firstDayMonday? 7 : 6;

    static max(DateTime d1, DateTime d2) {
        int diff = d1.compareTo(d2);
        return (diff > 0)? d1 : d2;
    }

    static min(DateTime d1, DateTime d2) {
        int diff = d1.compareTo(d2);
        return (diff < 0)? d1 : d2;
    }

    static bool dateBetween(DateTime date, DateTime end1, DateTime end2) {
        DateTime start = min(end1, end2);
        DateTime end = max(end1, end2);
        if(date.isAfter(start) && date.isBefore(end) || date.compareTo(start) == 0 || date.compareTo(end) == 0)
            return true;
        return false;
    }

    static offset() => firstDayMonday? 2 : 1;

    static day(int num) {
        if(firstDayMonday) {
            num += 1;
            if(num > 6)
                num = 0;
        }
        return label_days[num];
    }

    static dayFromDate(int weekday) {
        if(weekday == 7)
            weekday = 0;
        return label_days[weekday];
    }

    static isWeekend(int num) {
        if(firstDayMonday) {
            if(num == 5 || num == 6)
                return true;
        } else {
            if(num == 0 || num == 6)
                return true;
        }
        return false;
    }

    static isWeekendFromDate(int weekday) {
        if(weekday == 6 || weekday == 7)
            return true;
        return false;
    }

    static month(int num) {
        return label_months[num];
    }

    static textChoosePeriod() {
        return INTL.Choose_period();
    }

    static textToday() {
        return INTL.today();
    }

    static textEmpty() {
        return INTL.empty();
    }

    static textDone() {
        return INTL.done();
    }

	static _getRange (DateTime d, DateTime n) {
    	return [d, n];
    }

    static parse(String date) {
        DateTime d;
        try { d = new DateFormat('dd/MM/yyyy').parse(date);} catch(e) {
            try { d = new DateFormat('yyyy-MM-dd').parse(date);} catch(e) {
                d = null;
            }
        }
        return d;
    }

    static parseWithTime(String date) {
        DateTime d;
        try { d = new DateFormat('dd/MM/yyyy HH:mm').parse(date);} catch(e) {
            try { d = new DateFormat('yyyy-MM-dd HH:mm').parse(date);} catch(e) {
                d = null;
            }
        }
        return d;
    }

    static parseYear(String date) {
        DateTime d;
        try {d = new DateFormat('yyyy').parse(date);} catch(e) {
            d = null;
        }
        return d;
    }

    static parseYearMonth(String date) {
        DateTime d;
        try {d = new DateFormat('yyyy-MM').parse(date);} catch(e) {
            d = null;
        }
        return d;
    }

    static string(DateTime date) {
        return new DateFormat('dd/MM/yyyy').format(date);
    }

    static stringWithtTime(DateTime date) {
        return new DateFormat('dd/MM/yyyy HH:mm').format(date);
    }

    static getDateRange () {
    	var d = new DateTime.now();
        return _getRange(d, d);
    }

    static getMonthRange () {
		var d = new DateTime.now();
        return _getRange(new DateTime(d.year, d.month, 1), new DateTime(d.year, d.month, new DateTime(d.year, d.month + 1, 0).day));
    }

    static getYearRange () {
        var d = new DateTime.now();
        return _getRange(new DateTime(d.year, 0, 1), new DateTime(d.year, 11, 31));
    }

    static getWeeksBackRange ([int diff = 1]) {
        var d = new DateTime.now();
        return _getRange(d.subtract(new Duration(days:diff*7)), d);
    }

    static getMonthsBackRange ([int diff = 1]) {
		var d = new DateTime.now();
        return _getRange(d.subtract(new Duration(days:diff*30)), d);
    }

    static getYearsBackRange ([int diff = 1]) {
		var d = new DateTime.now();
        return _getRange(d.subtract(new Duration(days:diff*365)), d);
    }

    static getTodayRange () {
        var d = new DateTime.now();
        return _getRange(d, d);
    }

    static getYesterdayRange () {
		var d = new DateTime.now();
		d = d.subtract(new Duration(days:1));
        return _getRange(d, d);
    }

    static getThisWeekRange () {
        var n = new DateTime.now();
        var diff = n.weekday - 1;
        diff = (diff < 0)? 6 : diff;
		var d = n.subtract(new Duration(days:diff));
        return _getRange(d, n);
    }

    static getLastWeekRange () {
        var d = new DateTime.now();
        var n = new DateTime.now();
		n = n.subtract(new Duration(days:n.weekday));
		d = n.subtract(new Duration(days:6));
        return _getRange(d, n);
    }

    static getThisMonthRange () {
        var n = new DateTime.now();
        var d = new DateTime(n.year, n.month, 1);
        return _getRange(d, n);
    }

    static getLastMonthRange () {
		var h = new DateTime.now();
		var n = new DateTime(h.year, h.month, 1);
		n = n.subtract(new Duration(days:1));
		var d = new DateTime(n.year, n.month, 1);
        return _getRange(d, n);
    }

    static getThisYearRange () {
		var n = new DateTime.now();
        var d = new DateTime(n.year, 1, 1);
        return _getRange(d, n);
    }

    static getLastYearRange () {
        var h = new DateTime.now();
		var d = new DateTime(h.year -1, 1, 1);
		var n = new DateTime(h.year -1 , 12, 31);
        return _getRange(d, n);
    }

    static getAllRange () {
        return _getRange(new DateTime(2000, 0, 1), new DateTime.now());
    }

	static getDayString (DateTime date) {
      	return label_days[date.weekday - 1].substring(0, 3);
	}

	static getMonthString (DateTime date) {
      	return label_months[date.month - 1].substring(0, 3);
	}

}

math.Point boundPoint(math.Point p, math.Point ref1, math.Point ref2) {
    var max = (math.Point p, math.Point ref) => new math.Point(math.max(p.x, ref.x), math.max(p.y, ref.y));
    var min = (math.Point p, math.Point ref) => new math.Point(math.min(p.x, ref.x), math.min(p.y, ref.y));
    return min(max(p, ref1), ref2);
}

math.MutableRectangle boundRect(Rectangle rect, Rectangle ref) {
    math.Point point = boundPoint(rect.bottomRight, ref.topLeft, ref.bottomRight);
    return new math.MutableRectangle(point.x - rect.width, point.y - rect.height, rect.width, rect.height);
}

math.MutableRectangle centerRect(Rectangle rect, Rectangle ref) {
    math.MutableRectangle box = new math.MutableRectangle.fromPoints(rect.topLeft, rect.bottomRight);
    box.left = ref.left + ref.width ~/2 - box.width ~/2;
    box.top = ref.top + ref.height ~/2 - box.height ~/2;
    return box;
}

getScrollbarWidth() {
    var outer = new DivElement()
    	..style.width = "100px"
    	..style.height = "100px";
    document.body.append(outer);
    var widthNoScroll = outer.offsetWidth;
    outer.style.overflow = "scroll";
    var inner = document.createElement("div")
    	..style.width = "100%";
    outer.append(inner);
    var widthWithScroll = inner.offsetWidth;
    outer.remove();
    return widthNoScroll - widthWithScroll;
}