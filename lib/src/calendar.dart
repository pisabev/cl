part of calendar;

class Event {

    DateTime start, end;

    String title = 'No title';

    bool full_day;

    Event(DateTime start,  DateTime end, [this.full_day = true]) {
        this.start = utils.Calendar.min(start, end);
        this.end = utils.Calendar.max(start, end);
    }

    toString() => '${start} - ${end}';

    bool isPassed() {
        DateTime now = new DateTime.now();
        return (now.compareTo(end) > 0)? true : false;
    }

    bool isAllDayEvent() => full_day;

}

class EventCollection {

    List events = new List();

    Expando rendered = new Expando();

    bool days = true;

    List<Event> getEarliestEvents(List<Event> events, [bool noRendered = false]) {
        if(events.length == 0)
            return [];
        List temp = noRendered? events.where((event) => !rendered[event]).toList() : events;
        if(temp.length == 0)
            return [];
        DateTime min = null;
        temp.forEach((Event event) => min = (min == null)? event.start : utils.Calendar.min(event.start, min));
        return temp.where((event) => event.start == min).toList();
    }

    int _diff(DateTime date_start, DateTime date_end)  =>
        days? date_end.difference(date_start).inDays :
        date_end.difference(date_start).inMinutes;

    Event getLongestEvent(List<Event> events, [bool noRendered = false]) {
        if(events.length == 0)
            return null;
        List temp = noRendered? events.where((event) => !rendered[event]).toList() : events;
        if(temp.length == 0)
            return null;
        int max = 0;
        temp.forEach((Event event) => max = math.max(_diff(event.start, event.end), max));
        return temp.firstWhere((event) => _diff(event.start, event.end) == max);
    }

    List<Event> getEventsInSpot(DateTime date, [bool noRendered = false]) {
        return noRendered?
        events.where((event) => (!rendered[event] && event.start.compareTo(date) == 0)).toList() :
        events.where((event) => (event.start.compareTo(date) == 0)).toList();
    }

    List<Event> getEventsAfterSpot(DateTime date, [bool noRendered = false]) {
        return noRendered?
        events.where((event) => (event.start.compareTo(date) > 0) && !rendered[event]).toList() :
        events.where((event) => (event.start.compareTo(date) > 0)).toList();
    }

    List<Event> getEventsAfterEqualSpot(DateTime date, [bool noRendered = false]) {
        return noRendered?
        events.where((event) => (event.start.compareTo(date) >= 0) && !rendered[event]).toList() :
        events.where((event) => (event.start.compareTo(date) >= 0)).toList();
    }

    bool isEventsRendered() => events.any((event) => !rendered[event]);


    Event getNextEvent([bool noRendered = false]) {
        return getLongestEvent(getEarliestEvents(events, noRendered));
    }

    Event getNextEventSibling(Event event, [bool noRendered = false]) {
        return getLongestEvent(getEarliestEvents(getEventsAfterSpot(event.end, noRendered)));
    }

    Event getNextEventEqualSibling(Event event, [bool noRendered = false]) {
        return getLongestEvent(getEarliestEvents(getEventsAfterEqualSpot(event.end, noRendered)));
    }

    Map<int, List<Event>> _readEvents(List<Event> events) {
        int row = 0;
        Map m = new Map();
        while(isEventsRendered()) {
            row++;
            m[row] = new List();
            var ev = getNextEvent(true);
            while(ev != null) {
                rendered[ev] = true;
                m[row].add(ev);
                ev = getNextEventSibling(ev, true);
            }
        }
        return m;
    }

    Map<int, List<Event>> _readEvents2(List<Event> events) {
        int row = 0;
        Map m = new Map();
        while(isEventsRendered()) {
            row++;
            m[row] = new List();
            var ev = getNextEvent(true);
            while(ev != null) {
                rendered[ev] = true;
                m[row].add(ev);
                ev = getNextEventEqualSibling(ev, true);
            }
        }
        return m;
    }

}

class MonthCell extends CJSElement {

    DateTime date;

    MonthCell(cell, this.date) : super (cell);

}

class HourRow extends CJSElement {

    int hour;

    int minutes;

    HourRow(this.hour, this.minutes) : super (new DivElement()) {
        addClass('hour-grid');
    }

}

class DayCol extends CJSElement with EventCollection {

    DateTime date;

    EventCalendar calendar;

    List cells = new List();

    bool days = false;

    CJSElement day_cont, day_drag;

    DayCol(date, this.calendar) : super(new Element.td()) {
        this.date = calendar._normDate(date);
        var outer = new CJSElement(new DivElement()).setClass('day-container').appendTo(this);
        day_cont = new CJSElement(new DivElement()).setClass('day-inner').appendTo(outer);
        if(calendar.now.compareTo(this.date) == 0) {
            addClass('now');
            var mark = new CJSElement(new DivElement()).setClass('hour-mark');
            var nh = new DateTime.now();
            mark.setStyle({'top':'${(nh.hour*60 + nh.minute)/1.43}px'});
            outer.append(mark);
        }
        day_drag = new CJSElement(new DivElement()).setClass('day-container-drag').appendTo(this);
    }

    _intersectEvents(List<Event> events) {
        if(events.length == 0)
            return null;
        List inter = new List();
        events.forEach((event) {
            if(!event.isAllDayEvent()
                && (date.compareTo(calendar._normDate(event.start)) == 0
                || date.compareTo(calendar._normDate(event.end)) == 0))
                inter.add(event);
        });
        return inter;
    }

    setEvents(List<Event> events) {
        rendered = new Expando();
        this.events = new List();
        if(events.length != 0)
            this.events.addAll(_intersectEvents(events));
    }

    _reset() {
        day_cont.removeChilds();
    }

    render() {
        _reset();
        if(events.length == 0)
            return;

        var data = _readEvents2(events);
        int length = data.length;
        double width_av = 100.0;
        double width = 100.0;
        int k = 0;
        if(length > 1) {
            width_av = 100 / length;
            width = (85 / length) * 2;
        }

        data.forEach((cur_row, events) {
            int k = cur_row - 1;
            events.forEach((Event event) {
                if(calendar.dragd.doms[event] == null)
                    calendar.dragd.doms[event] = new List();
                DateTime indx_start = utils.Calendar.max(event.start, new DateTime(date.year, date.month, date.day, 0, 0));
                DateTime indx_end = utils.Calendar.min(event.end, new DateTime(date.year, date.month, date.day, 24, 0));
                var cell_height = 21,
                    top = ((indx_start.hour * 60 + indx_start.minute)/30) * cell_height - 1,
                    height = _diff(indx_start, indx_end)/30 * cell_height + 2;
                var cont = new CJSElement(new DivElement())
                        .addClass('event-cont-hour')
                        .addAction((e) => e.stopPropagation(), 'mousedown'),
                    dom = new CJSElement(new DivElement())
                        .addClass('inner')
                        .appendTo(cont),
                    resize = new CJSElement(new DivElement())
                        .addClass('resize')
                        .addAction((e) => e.stopPropagation(), 'mousedown')
                        .setText('=').appendTo(cont);
                calendar.dragd.doms[event].add(cont);
                if(cur_row == length)
                    width = width_av;
                cont.setStyle({
                    'top':'${top}px',
                    'left':'${k*width_av}%',
                    'width':'${width}%',
                    'height':'${height}px'
                });
                day_cont.append(cont);
                new utils.Drag(cont)
                ..start((e) => calendar.dragd.set(event, e.client.x, e.client.y))
                ..on((e) => calendar.dragd.move(e.client.x, e.client.y))
                ..end(calendar.dragd.release);
                utils.Drag drag = new utils.Drag(resize)
                ..start((e) => calendar.dragd.resize(event))
                ..on((e) => calendar.dragd.resizeMove(e.client.x, e.client.y))
                ..end(calendar.dragd.release);
            });
        });
    }

}

class MonthRow extends CJSElement with EventCollection {

    CJSElement table_main, table_grid, tbody_main, tbody_grid;

    EventCalendar calendar;

    List<DateTime> dates;

    List cells = new List();

    MonthRow(dates, this.calendar) : super(new DivElement()) {
        this.dates = dates.map((date) => calendar._normDate(date)).toList();
        createDom();
    }

    createDom() {
        addClass('cal-row');
        table_main = new CJSElement(new TableElement())..appendTo(this)..addClass('cal-back');
        table_grid = new CJSElement(new TableElement())..appendTo(this)..addClass('cal-grid');
        tbody_main = new CJSElement(table_main.dom.createTBody())..appendTo(table_main);
        tbody_grid = new CJSElement(table_main.dom.createTBody())..appendTo(table_grid);
        TableRowElement row_main = tbody_main.dom.insertRow(-1);
        TableRowElement row_grid_title = tbody_grid.dom.insertRow(-1);

        var over = false;
        for(int i = 0; i < dates.length; i++) {
            var cell = new MonthCell(row_main.insertCell(-1), dates[i]);
            if(dates[i].compareTo(calendar.now) == 0)
                cell.addClass('now');
            cells.add(cell);
            var title = row_grid_title.insertCell(-1);
            if(dates[i].month != calendar.cur.month) {
                title.className = 'blur';
                if(dates[i].day == 1)
                    title.innerHtml = '${utils.Calendar.month(dates[i].month - 1).substring(0,3)} ${dates[i].day}';
                else
                    title.innerHtml = '${dates[i].day}';
            } else
                title.innerHtml = '${dates[i].day}';
        };
    }

    getMonthCell(DateTime date) {
        return cells.firstWhere((MonthCell mc) => mc.date.compareTo(date) == 0);
    }

    _intersectEvents(List<Event> events) {
        if(events.length == 0)
            return null;
        List inter = new List();
        DateTime range_first = dates.first;
        DateTime range_last = dates.last;
        events.forEach((event) {
            if((utils.Calendar.dateBetween(event.start, range_first, range_last) ||
            utils.Calendar.dateBetween(event.end, range_first, range_last) ||
            utils.Calendar.dateBetween(range_first, event.start, event.end))) {
                inter.add(event);
            }
        });
        return inter;
    }

    setEvents(List<Event> events) {
        rendered = new Expando();
        this.events = new List();
        if(events.length != 0) {
            this.events.addAll(_intersectEvents(events));
        }
    }

    _reset() {
        List for_clear = new List();
        for (int i = 1; i < tbody_grid.dom.children.length; i++)
            for_clear.add(tbody_grid.dom.children[i]);
        for_clear.forEach((row) => row.remove());
    }

    render() {
        _reset();
        if(events.length == 0)
            return;
        var data = _readEvents(events);
        int rows = data.length;
        int rows_rendered = 0;
        TableRowElement row;
        data.forEach((cur_row, events) {
            row = tbody_grid.dom.insertRow(-1);
            for (int j = 0; j < dates.length; j++)
                var cell = row.insertCell(-1);
            events.forEach((Event event) {
                DateTime event_start = calendar._normDate(event.start);
                DateTime event_end = calendar._normDate(event.end);
                DateTime indx_start = utils.Calendar.max(event_start, dates.first);
                DateTime indx_end = utils.Calendar.min(event_end, dates.last);
                var cell = new CJSElement(getIndexBydate(row, indx_start));
                cell.addAction((e) => e.stopPropagation(), 'mousedown');
                var r = _diff(indx_start, indx_end) + 1;
                cell.dom.colSpan = r;
                cell.setClass('event');
                var div = new CJSElement(new DivElement()).setClass('event-cont');
                if(event.isPassed())
                    div.addClass('light');
                if(event.isAllDayEvent()) {
                    if (indx_start.compareTo(event_start) > 0) {
                        new CJSElement(new DivElement()).setClass('arrow-left1').appendTo(div);
                        new CJSElement(new DivElement()).setClass('arrow-left2').appendTo(div);
                        div.addClass('margin-left');
                    }
                    if (indx_end.compareTo(event_end) < 0) {
                        new CJSElement(new DivElement()).setClass('arrow-right1').appendTo(div);
                        new CJSElement(new DivElement()).setClass('arrow-right2').appendTo(div);
                        div.addClass('margin-right');
                    }
                } else {
                    div.addClass('day');
                }

                div.append(new Text(event.title));

                var drg, rect;
                setDragPos(drg, rect, e) =>
                    drg.setStyle({'top':'${e.page.y - rect.top - 10}px', 'left':'${e.page.x - rect.left - 50}px'});
                new utils.Drag(div)
                    ..start((e) {
                        drg = new CJSElement(new DivElement())
                            .setClass('event-cont-drag')
                            .setText(event.title)
                            .appendTo(div);
                        rect = div.getRectangle();
                        setDragPos(drg, rect, e);
                        calendar.dragm.onDragEvent(e, event);
                    })
                    ..on((e) {
                        setDragPos(drg, rect, e);
                        calendar.dragm.onDragEvent(e, event);
                    })
                    ..end((e) {
                        drg.remove();
                        calendar.dragm.onDropEvent(e, event);
                    });
                cell.append(div);
                int i = 0;
                while(i < r - 1) {
                    cell.dom.nextElementSibling.remove();
                    i++;
                }
            });
        });

    }

    getIndexBydate(row, date) {
        int indx = dates.indexOf(date);
        if(indx == 0)
            return row.cells[indx];
        int index = 0;
        for(int i = 0; i < row.cells.length; i++) {
            if(index == indx)
                return row.cells[i];
            index += row.cells[i].colSpan;
        }
    }

}

class WeekRow extends MonthRow {

    WeekRow(dates, calendar) : super(dates, calendar);

    _intersectEvents(List<Event> events) {
        if(events.length == 0)
            return null;
        List inter = new List();
        DateTime range_first = dates.first;
        DateTime range_last = dates.last;
        events.forEach((event) {
            if(event.isAllDayEvent() && (utils.Calendar.dateBetween(event.start, range_first, range_last) ||
            utils.Calendar.dateBetween(event.end, range_first, range_last) ||
            utils.Calendar.dateBetween(range_first, event.start, event.end))) {
                inter.add(event);
            }
        });
        return inter;
    }

    createDom() {
        addClass('cal-row week');
        table_main = new CJSElement(new TableElement())..appendTo(this)..addClass('cal-back week');
        table_grid = new CJSElement(new TableElement())..appendTo(this)..addClass('cal-grid week');
        tbody_main = new CJSElement(table_main.dom.createTBody())..appendTo(table_main);
        tbody_grid = new CJSElement(table_main.dom.createTBody())..appendTo(table_grid);
        TableRowElement row_main = tbody_main.dom.insertRow(-1);
        TableRowElement row_grid_title = tbody_grid.dom.insertRow(-1);

        var over = false;
        for(int i = 0; i < dates.length; i++) {
            var cell = new MonthCell(row_main.insertCell(-1), dates[i]);
            if(dates[i].compareTo(calendar.now) == 0) {
                cell.addClass('now');
                cell.append(new SpanElement());
            }
            cells.add(cell);
            var title = row_grid_title.insertCell(-1);
        };
    }

    render() {
        super.render();
        table_main.setStyle({'height':'${tbody_grid.getHeight()}px'});
        calendar.setBodyHeight();
    }

}

class EventCalendar {

    Container dom, cal, nav, body;
    CJSElement head, domMonth, week_dom, day_cont;

    List<Event> events = new List();

    DateTime now, cur;

    CJSElement contr_left, contr_right;

    CalendarHelper calendar_helper;

    action.ButtonGroup button;

    DragMonthContainer dragm;
    DragDayContainer dragd;

    EventCalendar(container) {
        dom = new Container()..appendTo(container);
        dom.addClass('ui-event-calendar');
        cal = new Container()..setClass('left');
        nav = new Container()..setClass('cal-navigation');
        body = new Container()..setClass('cal-body');
        dom.addCol(cal);
        dom.addRow(nav);
        dom.addRow(body..auto = true);
        var nav_left = new CJSElement(new DivElement())..setClass('cal-nav-left').appendTo(nav),
            nav_right = new CJSElement(new DivElement())..setClass('cal-nav-right').appendTo(nav);

        new action.Button()
        .setTitle(INTL.Today())
        .setStyle({'margin-right':'3px'})
        .addAction((e) {
            cur = new DateTime.now();
            button.current.dom.click();
            calendar_helper.cur = cur;
            calendar_helper.set();
        })
        .appendTo(nav_left);

        contr_left = new action.Button()
        .setIcon('controls-previous')
        .appendTo(nav_left);

        contr_right = new action.Button()
        .setIcon('controls-next')
        .appendTo(nav_left);

        button = new action.ButtonGroup();
        button.addSub(new action.Button()
        .setTitle('Month')
        .addAction((e) => setViewMonth()));
        button.addSub(new action.Button()
        .setTitle('Week')
        .addAction((e) => setViewWeek()));
        button.addSub(new action.Button()
        .setTitle('Day')
        .addAction((e) => setViewDay()));
        button.appendTo(nav_right);

        button.setCurrent(1);

        domMonth = new CJSElement(new ParagraphElement())..appendTo(nav_left);

        var n = new DateTime.now();
        now = new DateTime(n.year, n.month, n.day);
        cur = now;

        calendar_helper = new CalendarHelper();
        calendar_helper.calendar = this;
        calendar_helper.set();
        cal.append(calendar_helper);
    }

    setEvents(List<Event> events) => this.events = events;

    addEvent(Event event) => events.add(event);

    removeEvent(Event event) => events.remove(event);

    setViewMonth() {
        button.setCurrent(0);
        List arr = _setViewMonth();
        calendar_helper.setRange(cur, arr[0], arr[1]);
    }

    setViewWeek() {
        button.setCurrent(1);
        List dates = _weekSlices(cur);
        _setViewDays(dates.first.first, dates.first.last);
        calendar_helper.setRange(dates.first.last, dates.first.first, dates.first.last);
    }

    setViewDay() {
        button.setCurrent(2);
        _setViewDays(cur);
        calendar_helper.setRange(cur, cur, cur);
    }

    setView(DateTime start_date, DateTime end_date) {
        button.setCurrent();
        if(start_date.difference(end_date).inDays.abs() > 6) {
            List start_slice = _weekSlices(start_date).first;
            List end_slice = _weekSlices(end_date).first;
            var start = new DateTime(cur.year, cur.month, 1);
            var end = utils.Calendar.UTCAdd(start, utils.Calendar.UTCDifference(new DateTime(cur.year, cur.month + 1, 0), start));
            if(start_slice.any((date) => start.compareTo(date) == 0) &&
                end_slice.any((date) => end.compareTo(date) == 0)) {
                button.setCurrent(0);
                _setViewMonth();
            } else
                _setViewMonthSection(start_date, end_date);
        } else
            _setViewDays(start_date, end_date);
    }

    _setViewMonth () {
        contr_left.removeActionsAll().addAction((e) {
            cur = new DateTime(cur.year, cur.month - 1);
            List arr = _setViewMonth();
            calendar_helper.setRange(cur, arr[0], arr[1]);
        }, 'click');
        contr_right.removeActionsAll().addAction((e) {
            cur = new DateTime(cur.year, cucr.month + 1);
            List arr = _setViewMonth();
            calendar_helper.setRange(cur, arr[0], arr[1]);
        }, 'click');
        _setTitle(cur);
        _prepareViewMonth();

        var rows = new List(),
        cells = new List();

        List prelist = new List.generate(6, (_) => new List());
        int offset = new DateTime(cur.year, cur.month).weekday - utils.Calendar.offset(),
        k = -1;
        for (var i = 0; i < 42; i++) {
            if (i%7==0) k++;
            prelist[k].add(new DateTime(cur.year, cur.month, i - offset));
        }
        List month_rows = new List();
        prelist.forEach((List dates) {
            if(dates.any((date) => date.month == cur.month))
                month_rows.add(dates);
        });

        var height = ((body.getHeight() - head.getHeight())/month_rows.length).ceil();
        month_rows.forEach((row) {
            MonthRow el = new MonthRow(row, this).appendTo(body).setStyle({'height':'${height}px'});
            el.setEvents(events);
            dragm.setDragable(el);
            el.render();
            cells.addAll(el.cells);
            rows.add(el);
        });
        dragm.rows = rows;
        dragm.cells = cells;

        return [month_rows.first.first, month_rows.last.last];

    }

    _setViewMonthSection (DateTime start_date, DateTime end_date) {
        _setContr(start_date, end_date, _setViewMonthSection);
        _setTitle(start_date, end_date);
        _prepareViewMonth();

        var rows = new List(),
        cells = new List();
        cur = end_date;
        var month_rows = _weekSlices(start_date, end_date);
        var height = ((body.getHeight() - head.getHeight())/month_rows.length).ceil();
        month_rows.forEach((row) {
            MonthRow el = new MonthRow(row, this).appendTo(body).setStyle({'height':'${height}px'});
            el.setEvents(events);
            dragm.setDragable(el);
            el.render();
            cells.addAll(el.cells);
            rows.add(el);
        });
        dragm.rows = rows;
        dragm.cells = cells;
    }

    _setViewDays (DateTime start_date, [DateTime end_date = null]) {
        if(end_date == null)
            end_date = start_date;

        _setContr(start_date, end_date, _setViewDays);
        _setTitle(start_date, end_date);

        end_date = end_date.add(new Duration(days:1));

        List<DateTime> dates = new List();
        DateTime next_date = start_date;
        while(next_date.compareTo(end_date) != 0) {
            dates.add(next_date);
            next_date = next_date.add(new Duration(days:1));
        }
        body.removeChilds();
        head = new CJSElement(new TableElement())..setClass('week-head')..appendTo(body);
        week_dom = new CJSElement(new DivElement())..setClass('week-cont')..appendTo(body);
        var table_scroll = new CJSElement(new TableElement())..setClass('week-scroll')..appendTo(week_dom);
        var thead_top = new CJSElement(head.dom.createTHead())..appendTo(head),
            tbody_top = new CJSElement(head.dom.createTBody())..appendTo(head);

        var thead = new CJSElement(table_scroll.dom.createTHead())..appendTo(table_scroll),
            tbody = new CJSElement(table_scroll.dom.createTBody())..appendTo(table_scroll);

        TableRowElement row = tbody_top.dom.insertRow(-1);
        TableRowElement row_scroll_first = tbody.dom.insertRow(-1);
        TableRowElement row_scroll = tbody.dom.insertRow(-1);

        var first = new Element.th()..className = 'first';
        first.rowSpan = 2;
        row.append(first);

        var first_scroll = new Element.td()..className = 'first_scroll';
        var first_scroll2 = new Element.td()..className = 'first_scroll2';
        first_scroll2.colSpan = dates.length;
        row_scroll_first.append(first_scroll);
        row_scroll_first.append(first_scroll2);
        var hour = new Element.td();
        hour.className = 'first';
        day_cont = new CJSElement(new DivElement()).setClass('day');
        first_scroll2.append(day_cont.dom);

        var mark = new CJSElement(new DivElement()).setClass('hour-mark');
        var nh = new DateTime.now();
        hour.append(mark.dom);
        row_scroll.append(hour);
        mark.setStyle({'top':'${(nh.hour*60 + nh.minute)/1.43 - mark.getHeight()/2}px'});

        var hour_rows = new List();
        for(int i = 0; i < 24; i++) {
            var h = (i<10)? '0$i' : '$i';
            var t = new CJSElement(new DivElement()).setClass('hour')..dom.text = '$i:00';
            hour.append(t.dom);
            for(int j = 0; j < 2; j++) {
                var hr = new HourRow(i, j*30);
                day_cont.append(hr);
                hour_rows.add(hr);
            }
        }

        TableRowElement row_top_events = head.dom.insertRow(-1);
        var cell_top_events = new Element.td();
        cell_top_events.colSpan = dates.length;
        row_top_events.append(cell_top_events);
        new CJSElement(new DivElement()).appendTo(body).setClass('closing');

        dragm = new DragMonthContainer(body)..calendar = this;
        dragd = new DragDayContainer()..calendar = this;

        MonthRow month_row = new WeekRow(dates, this).appendTo(cell_top_events);
        month_row.setEvents(events);
        dragm.setDragable(month_row);
        dragm.cells = month_row.cells;
        dragm.rows = [month_row];
        month_row.render();

        dragd.hour_rows = hour_rows;
        dragd.day_cols = new List();
        for (var day = 0; day < dates.length; day++) {
            var cell = new Element.th();
            row.append(cell);
            DayCol dc = new DayCol(dates[day], this);
            dc.setEvents(events);
            dragd.setDragable(dc);
            dc.render();
            dragd.day_cols.add(dc.appendTo(row_scroll));
            cell.text = '${utils.Calendar.dayFromDate(dates[day].weekday).substring(0, 3)} ${dates[day].month}/${dates[day].day}';
            cell.className = utils.Calendar.isWeekendFromDate(dates[day].weekday)? 'weekend' : '';
        }
        row.append(new Element.td()..style.width = '${utils.getScrollbarWidth()}px');

        setBodyHeight();
    }

    _prepareViewMonth() {
        body.removeChilds();
        head = new CJSElement(new TableElement())..setClass('cal-head')..appendTo(body);
        var thead = new CJSElement(head.dom.createTHead())..appendTo(head),
        tbody = new CJSElement(head.dom.createTBody())..appendTo(head);

        TableRowElement row = thead.dom.insertRow(-1);
        for (var day = 0; day < 7; day++) {
            var cell = new Element.th();
            row.append(cell);
            cell.text = utils.Calendar.day(day).substring(0, 3);
            cell.className = utils.Calendar.isWeekend(day)? 'weekend' : '';
        }

        dragm = new DragMonthContainer(body);
        dragm.calendar = this;
    }

    setBodyHeight() {
        var height = ((body.getHeight() - head.getHeight()) - 10).floor();
        week_dom.setStyle({'height':'${height}px'});
    }

    _weekSlices(DateTime start, [DateTime end]) {
        _firstDate(DateTime date) {
            while (date.weekday != utils.Calendar.weekDayFirst())
                date = new DateTime(date.year, date.month, date.day - 1);
            return date;
        }

        _endDate(DateTime date) {
            while (date.weekday != utils.Calendar.weekDayLast())
                date = new DateTime(date.year, date.month, date.day + 1);
            return date;
        }
        if(end == null)
            end = start;
        start = _firstDate(start);
        end = _endDate(end);
        List list = new List();
        int k = -1;
        for(int i = 0; i < 42; i++) {
            DateTime cur = new DateTime(start.year, start.month, start.day + i);
            if (i%7==0) k++;
            if(list.length <= k)
                list.add(new List());
            list[k].add(cur);
            if(cur.isAtSameMomentAs(end))
                break;
        }
        return list;
    }

    _setContr(DateTime start, DateTime end, callback) {
        var step = utils.Calendar.UTCDifference(start, end).inDays.abs() + 1;
        contr_left.removeActionsAll().addAction((e) {
            start = new DateTime(start.year, start.month, start.day - step);
            end = new DateTime(end.year, end.month, end.day - step);
            callback(start, end);
            calendar_helper.setRange(end, start, end);
            cur = end;
        }, 'click');
        contr_right.removeActionsAll().addAction((e) {
            start = new DateTime(start.year, start.month, start.day + step);
            end = new DateTime(end.year, end.month, end.day + step);
            callback(start, end);
            calendar_helper.setRange(end, start, end);
            cur = end;
        }, 'click');
    }

    _setTitle(DateTime start, [DateTime end]) {
        if(end == null) {
            domMonth.setHtml('${utils.Calendar.month(start.month - 1)} ${start.year}');
        } else if(start.compareTo(end) == 0) {
            domMonth.setHtml('${utils.Calendar.dayFromDate(start.weekday)}, ${utils.Calendar.month(start.month - 1).substring(0,3)} ${start.day}, ${start.year}');
        } else {
            var month_start = utils.Calendar.month(start.month - 1).substring(0, 3);
            var month_end = end.month == start.month ? '' : ' ${utils.Calendar.month(end.month - 1).substring(0, 3)} ';
            var year_start = end.year == start.year ? '' : ', ${start.year}';
            domMonth.setHtml('${month_start} ${start.day}${year_start} - ${month_end}${end.day}, ${end.year}');
        }
    }

    _normDate(DateTime date) => new DateTime(date.year, date.month, date.day);

    changed() {
        calendar_helper.set();
    }

    layout() {
        dom.fillParent();
        dom.initLayout();
        button.current.dom.click();
        calendar_helper.set();
    }

}

class DragMonthContainer {

    CJSElement dom, drag_cont;

    EventCalendar calendar;

    List rows, cells;

    MonthCell start_cell, end_cell;

    DragMonthContainer(this.dom) {
        drag_cont = new CJSElement(new DivElement()).setClass('drag-cont');
    }

    setDragable(MonthRow row) {
        new utils.Drag(row)
            ..start(onDrag)
            ..on(onDrag)
            ..end(release);
    }

    MonthCell getCellByEvent(e) {
        return cells.firstWhere((MonthCell cell) => cell.getRectangle().containsPoint(new math.Point(e.client.x, e.client.y)), orElse: () => null);
    }

    onDrag(e) {
        MonthCell cell = getCellByEvent(e);
        if(cell == null)
            return;
        if (start_cell == null)
            start_cell = cell;
        highLight(start_cell, cell);
    }

    onDragEvent(e, Event drag) {
        MonthCell cell = getCellByEvent(e);
        if(cell == null)
            return;
        var offset_date = utils.Calendar.UTCAdd(cell.date, utils.Calendar.UTCDifference(drag.end, drag.start));
        var cell2 = cells.firstWhere((MonthCell mc) => mc.date.compareTo(offset_date) == 0, orElse: () => null);
        if(!drag.isAllDayEvent())
            cell2 = cell;
        highLight(cell, cell2);
    }

    onDropEvent(e, Event drag) {
        DateTime new_start = drag.start.add(start_cell.date.difference(calendar._normDate(drag.start)));
        DateTime new_end = new_start.add(drag.end.difference(drag.start));
        drag.start = new_start;
        drag.end = new_end;
        drag_cont.remove();
        rows.forEach((MonthRow row) {
            row.setEvents(calendar.events);
            row.render();
        });
        calendar.changed();
        start_cell = null;
        end_cell = null;
    }

    highLight(MonthCell start, MonthCell end) {
        start_cell = start;
        end_cell = (end != null)? end : cells.last;
        drag_cont.removeChilds().appendTo(dom);
        Map m = new Map();
        cells.forEach((cell) {
            if(utils.Calendar.dateBetween(cell.date, start_cell.date, end_cell.date)) {
                math.MutableRectangle rect = cell.getRectangle();
                if(m[rect.top] == null)
                    m[rect.top] = new List();
                m[rect.top].add(rect);
            }
        });
        math.Rectangle top = calendar.body.getRectangle();
        m.forEach((k, v) {
            math.Rectangle rect = v.first;
            new CJSElement(new DivElement())
            .setClass('grid')
            .setStyle({
                'width': '${v.last.left - rect.left + rect.width + 1}px',
                'height': '${rect.height}px',
                'top': '${rect.top + document.body.scrollTop - top.top}px',
                'left': '${rect.left + document.body.scrollLeft - top.left}px'
            })
            .append(new SpanElement())
            .appendTo(drag_cont);
        });
    }

    release(e) {
        drag_cont.remove();
        calendar.events.add(new Event(start_cell.date, end_cell.date, true));
        rows.forEach((MonthRow row) {
            row.setEvents(calendar.events);
            row.render();
        });
        calendar.changed();
        start_cell = null;
        end_cell = null;
    }
}

class DragDayContainer {

    List hour_rows;
    List day_cols;

    List<Map> rects;

    Event event_sel;

    EventCalendar calendar;

    DateTime start_date, end_date, click_date;

    double ratio = 1.43;

    Expando doms = new Expando();
    List dm = new List();

    DragDayContainer ();

    set(Event event, int x, int y) {
        event_sel = event;
        click_date = getDateByCoords(x, y);
        doms[event].forEach((dom) => dom.hide());
        _drawRects(event_sel.start, event_sel.end);
    }

    move(int x, int y) {
        DateTime cur = getDateByCoords(x, y);
        if(cur == null)
            return;
        Duration diff = cur.difference(click_date);
        DateTime new_start = event_sel.start.add(diff);
        DateTime new_end = event_sel.end.add(diff);
        _drawRects(new_start, new_end);
    }

    resize(Event event) {
        event_sel = event;
        doms[event].forEach((dom) => dom.hide());
        _drawRects(event_sel.start, event_sel.end);
    }

    resizeMove(int x, int y) {
        DateTime stretch_date = getDateByCoords(x, y);
        _drawRects(event_sel.start, stretch_date);
    }

    release(e) {
        if(start_date == null || end_date == null || start_date.compareTo(end_date) == 0)
            return;
        dm.forEach((d) => d.remove());
        dm = new List();
        calendar.removeEvent(event_sel);
        calendar.addEvent(new Event(start_date, end_date, false));
        day_cols.forEach((DayCol dc) {
            dc.setEvents(calendar.events);
            dc.render();
        });
        calendar.changed();
        start_date = null;
        end_date = null;
    }

    setDragable(DayCol dc) {
        DateTime date1;
        DateTime date2;
        new utils.Drag(dc)
            ..start((e) => date1 = getDateByCoords(e.client.x, e.client.y))
            ..on((e) {
                date2 = getDateByCoords(e.client.x, e.client.y);
                _drawRects(utils.Calendar.min(date1, date2), utils.Calendar.max(date1, date2));
            })
            ..end(release);
    }

    _drawRects(DateTime start, DateTime end) {
        start_date = start;
        end_date = end;
        if(start.compareTo(end) == 0)
            return;
        rects = getDayRectByDates(start, end);
        dm.forEach((d) => d.remove());
        dm = new List();
        rects.forEach((rect) {
            if(rect != null) {
                CJSElement drag_cont = rect['day'].day_drag;
                var t = drag_cont.getRectangle();
                math.MutableRectangle rectangle = rect['rect'];
                rectangle.top -= t.top;
                rectangle.left = 0;
                var e = new CJSElement(new DivElement()).setClass('day-event').setRectangle(rectangle);
                drag_cont.append(e);
                dm.add(e);
            }
        });
    }

    HourRow getHourByCoords(int x, int y) =>
        hour_rows.firstWhere((HourRow row) => row.getRectangle().containsPoint(new math.Point(x, y)), orElse: () => null);

    DayCol getDayByCoords(int x, int y) =>
        day_cols.firstWhere((col) => col.getRectangle().containsPoint(new math.Point(x, y)), orElse: () => null);

    HourRow getHourRowByDate(DateTime date) {
        var hour = date.hour;
        var minute = date.minute;
        if(date.minute > 30) {
            hour += 1;
            minute = 0;
        }
        return hour_rows.firstWhere((HourRow row) => row.hour == date.hour && row.minutes == minute, orElse: () => null);
    }

    DayCol getDayColByDate(DateTime date) => day_cols.firstWhere((DayCol day) => day.date.day == date.day, orElse: () => null);

    DateTime getDateByCoords(int x, int y) {
        HourRow row = getHourByCoords(x, y);
        DayCol day = getDayByCoords(x, y);
        if(row == null || day == null)
            return null;
        return new DateTime(day.date.year, day.date.month, day.date.day, row.hour, row.minutes);
    }

    List getDayRectByDates(DateTime date_start, DateTime date_end) {
        if(date_start.day != date_end.day) {
            DateTime start_date_end = new DateTime(date_start.year, date_start.month, date_start.day, 23, 59);
            DateTime end_date_start = new DateTime(date_end.year, date_end.month, date_end.day, 0, 0);
            List f = getDayRectByDates(date_start, start_date_end);
            List s = getDayRectByDates(end_date_start, date_end);
            return [f.first, s.first];
        } else {
            HourRow r = getHourRowByDate(date_start);
            DayCol d = getDayColByDate(date_start);
            if(r == null || d == null)
                return [null];
            var rect = r.getRectangle().intersection(d.getRectangle());
            return [{
                'rect': new math.MutableRectangle(rect.left, rect.top, rect.width, (date_end.difference(date_start).inMinutes / ratio).ceil()),
                'day': d,
                'row': r
            }];
        }
    }

}

class CalendarHelper extends CJSElement {

    DateTime cur;

    EventCalendar calendar;

    CJSElement domTbody, domMonth;

    CalendarHelperDrag drag;

    DateTime range_start;
    DateTime range_end;

    CalendarHelper () : super(new DivElement()) {
        setClass('ui-calendar-helper');
        cur = new DateTime.now();
        createDom();
    }

    createDom () {
        var e = new DivElement();
        var nav = new CJSElement(new DivElement())..setClass('cal-nav').appendTo(this),
        nav_left = new CJSElement(new DivElement())..setClass('cal-nav-left').appendTo(nav),
        nav_right = new CJSElement(new DivElement())..setClass('cal-nav-right').appendTo(nav);

        new action.Button()
        .setIcon('controls-previous')
        .addAction((e) {
            cur = new DateTime(cur.year, cur.month - 1);
            set();
        }, 'click')
        .appendTo(nav_left);
        new action.Button()
        .setIcon('controls-next')
        .addAction((e) {
            cur = new DateTime(cur.year, cur.month + 1);
            set();
        }, 'click')
        .appendTo(nav_left);
        var label_month = new CJSElement(new ParagraphElement())..appendTo(nav_left);

        var table = new CJSElement(new TableElement())..appendTo(this);
        var thead = new CJSElement(table.dom.createTHead())..appendTo(table),
        tbody = new CJSElement(table.dom.createTBody())..appendTo(table);

        var row = thead.dom.insertRow(-1);
        for (var day = 0; day < 7; day++) {
            var cell = row.insertCell(-1);
            cell.className = utils.Calendar.isWeekend(day)? 'weekend' : '';
            cell.innerHtml = utils.Calendar.day(day).substring(0,1);
        }
        domMonth = label_month;
        domTbody = tbody;
    }

    set () {
        domTbody.removeChilds();
        domMonth.dom.text = '${utils.Calendar.month(cur.month - 1)} ${cur.year}';
        int offset = new DateTime(cur.year, cur.month).weekday - utils.Calendar.offset(),
            k = -1;
        var row;
        List rows = new List.generate(6, (_) => new List());
        var start_date = null;
        for (var i = 0; i < 42; i++) {
            row = (i%7==0)? domTbody.dom.insertRow(-1) : row;
            if(i%7==0) k++;
            var c = row.insertCell(-1)..className = utils.Calendar.isWeekend(i%7)? 'weekend' : '';
            CalendarHelperCell cell = new CalendarHelperCell(new SpanElement(), new DateTime(cur.year, cur.month, i - offset)).appendTo(c);
            if(cell.date.month != cur.month)
                cell.addClass('other');
            if(checkDateForEvents(cell.date))
                c.className = 'events';
            if(cell.date.isAtSameMomentAs(calendar.now))
                cell.addClass('today');
            cell.setText('${cell.date.day}');
            rows[k].add(cell);
        }
        drag = new CalendarHelperDrag(rows)
            ..calendar = calendar
            ..setDraggable();
        if(range_start != null && range_end != null)
            drag.setRange(range_start, range_end);
    }

    setRange(DateTime cur_view, [DateTime start, DateTime end]) {
        cur = cur_view;
        range_start = start;
        range_end = end;
        set();
    }

    checkDateForEvents(date) {
        return (calendar.events.any((Event event) {
            if(utils.Calendar.dateBetween(date, event.start, event.end) ||
            date.year == event.start.year && date.month == event.start.month && date.day == event.start.day)
                return true;
            return false;
        }))? true : false;
    }
}

class CalendarHelperCell extends CJSElement {

    DateTime date;

    CalendarHelperCell(cell, this.date) : super (cell);

}

class CalendarHelperDrag {

    EventCalendar calendar;

    List<List<CalendarHelperCell>> rows;

    CalendarHelperDrag(this.rows);

    CalendarHelperCell start_cell;

    setDraggable () {
        rows.forEach((row) {
            row.forEach((CalendarHelperCell cell) {
                cell.addAction((e) => startDrag(cell, e), 'mousedown');
                cell.addAction((e) => over(cell, e), 'mouseover');
            });
        });
        new CJSElement(document.body).addAction((e) {
            start_cell = null;
        },'mouseup');
    }

    _clear() {
        rows.forEach((row) {
            row.forEach((CalendarHelperCell cell) {
                cell.removeClass('selected');
            });
        });
    }

    fillRange(CalendarHelperCell start, CalendarHelperCell end, [bool full_row = false]) {
        var first, last;
        rows.forEach((row) {
            row.forEach((CalendarHelperCell cell) {
                if(full_row) {
                    if(start.date.compareTo(cell.date) == 0)
                        first = row.first;
                    if(end.date.compareTo(cell.date) == 0)
                        last = row.last;
                } else {
                    if (utils.Calendar.dateBetween(cell.date, start.date, end.date))
                        cell.addClass('selected');
                    else
                        cell.removeClass('selected');
                }
            });
        });
        if(full_row)
            fillRange(first, last);
        else
            calendar.setView(start.date, end.date);
    }

    setRange(DateTime start, DateTime end) {
        rows.forEach((row) {
            row.forEach((CalendarHelperCell cell) {
                if (utils.Calendar.dateBetween(cell.date, start, end))
                    cell.addClass('selected');
                else
                    cell.removeClass('selected');
            });
        });
    }

    startDrag(CalendarHelperCell cell, e) {
        start_cell = cell;
        _clear();
        cell.addClass('selected');
        over(cell, e);
    }

    over(CalendarHelperCell cell, e) {
        if(start_cell == null)
            return;
        if(cell.date.isAfter(start_cell.date))
            fillRange(start_cell, cell, (cell.date.difference(start_cell.date).inDays > 6)? true : false);
        else
            fillRange(cell, start_cell, (start_cell.date.difference(cell.date).inDays > 6)? true : false);
    }
}