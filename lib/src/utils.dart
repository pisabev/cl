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

	getHook (String scope) {
		return _hook[scope];
	}

	execHooks (String scope, [List<dynamic> list]) {
		bool ret = true;
		if(_hook[scope] is Queue) {
			Iterator i = _hook[scope].iterator;
			while(i.moveNext()) {
				var r = (list != null)? i.current(list) : i.current();
				if(r == false) {
					ret = false;
					break;
				}
			}
		}
		return ret;
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

class Draggable {
	CJSElement object;
	String namespace;
	Observer observer;

	bool enable = true;

	Draggable(CJSElement el, [String nspace = 'draggable']) {
		object = el;
		namespace = nspace;
		observer = new Observer();
		el.addAction(drag, 'mousedown' + '.' + nspace);
	}

	drag (MouseEvent e) {
		if(!enable)
			return;
		observer.execHooks('start', [e]);
		var document_move = document.onMouseMove.listen((e) {
			observer.execHooks('on', [e]);
		});
		var document_up = null;
		document_up = document.onMouseUp.listen((e) {
			document_move.cancel();
			document_up.cancel();
			observer.execHooks('stop', [e]);
		});
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

/*class Point {
	int x = 0;
	int y = 0;

	Point(int x, int y) {
		this.x = x;
		this.y = y;
	}

	Point operator +(Point p) {
		return new Point(x + p.x, y + p.y);
	}

	Point operator -(Point p) {
		return new Point(x - p.x, y - p.y);
	}

	Point min(Point p) {
		var _x = (x > p.x)? p.x : x;
		var _y = (y > p.y)? p.y : y;
		return new Point(_x, _y);
	}

	Point max(Point p) {
		var _x = (x < p.x)? p.x : x;
		var _y = (y < p.y)? p.y : y;
		return new Point(_x, _y);
	}

	Point bound(Point p1, Point p2) {
		return max(p1).min(p2);
	}

    toString() => {
        'x': x,
        'y': y
    }.toString();
}

class Box {

	Point p;
	int w;
	int h;

	Box(int x, int y, int w, int h) {
		p = new Point(x, y);
		this.w = w;
		this.h = h;
	}

	center(Box bound) {
		Box newBox = new Box(p.x, p.y, w, h);
		newBox.p.x = bound.p.x + bound.w ~/2 - newBox.w ~/2;
		newBox.p.y = bound.p.y + bound.h ~/2 - newBox.h ~/2;
  		return newBox;
	}

	bound(Box bound) {
		Point point = new Point(p.x + w, p.y + h);
		point = point.bound(bound.p, new Point(bound.p.x + bound.w, bound.p.y + bound.h));
		return new Box(point.x - w, point.y - h, w, h);
	}

    toString() => {
        'w': w,
        'h': h,
        'p': p
    }.toString();
}*/

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

class Calendar {

    static bool firstDayMonday = true;

    static List label_months = new DateFormat().dateSymbols.MONTHS;
		/*INTL.January(),
		INTL.February(),
		INTL.March(),
		INTL.April(),
		INTL.May(),
		INTL.June(),
		INTL.July(),
		INTL.August(),
		INTL.September(),
		INTL.October(),
		INTL.November(),
		INTL.December()
	];*/
    static List label_days = new DateFormat().dateSymbols.WEEKDAYS;
		/*INTL.Monday(),
		INTL.Tuesday(),
		INTL.Wednesday(),
		INTL.Thursday(),
		INTL.Friday(),
		INTL.Saturday(),
		INTL.Sunday()
    ];*/
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

    static weekDayFirst() => firstDayMonday? 1 : 7;

    static weekDayLast() => firstDayMonday? 7 : 1;

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