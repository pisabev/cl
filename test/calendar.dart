library test;

import 'package:cjs/app.dart' as cl_app;
import 'package:cjs/forms.dart' as cl_form;
import 'package:cjs/action.dart' as cl_action;
import 'package:cjs/gui.dart' as cl_gui;
import 'package:cjs/utils.dart' as cl_util;
import 'package:cjs/base.dart' as cl;
import 'package:cjs/calendar.dart' as calendar;
import 'dart:html';

part 'base.dart';

var ap = new cl_app.Application();
main() {
    var set = {
      'user': 'user',
      'menu': {'title': 'Menu', 'icon': 'user'},
      'menu_left': [],
      'menu_right': [
          {'title': 'Settings', 'action': (){}}
      ]
    };
    ap.initStartMenu('Test');

      //ap.gadgets.remove();

    cl_app.Win win = new cl_app.Win(ap.desktop);
    win.setTitle('Event calendar');
    win.render(1000, 600, 200, 200);

    var c = new calendar.EventCalendar(win.getContent());
    win.observer.addHook('layout', c.layout);
    win.initLayout();
    //c.setViewDays();
    //grid.appendTo(win.getContent());
    //grid.fillParent();

      //ap.set(set);
    /*var d = new DateTime(2015, 2, 1);
    var l = new DateTime(2015, 3, 1);
    print(d.difference(l).inDays);*/
    /*
    var diff = 10000;
    print(d.subtract(new Duration(days:diff)));
    print(d.timeZoneOffset);
    for(int i = 0; i < diff; i++) {
        d = new DateTime(d.year, d.month, d.day - 1);
    }
    print(d);
    print(d.timeZoneOffset);*/

    //print(_weekSlices(new DateTime(d.year, d.month, 1), new DateTime(d.year, d.month, 31)));

}

_weekSlices(DateTime date, DateTime end) {
    _firstDate(DateTime date) {
        while (date.weekday != cl_util.Calendar.weekDayFirst())
            date = new DateTime(date.year, date.month, date.day - 1);
        return date;
    }

    _endDate(DateTime date) {
        while (date.weekday != cl_util.Calendar.weekDayLast())
            date = new DateTime(date.year, date.month, date.day + 1);
        return date;
    }
    date = _firstDate(date);
    end = _endDate(end);
    List list = new List();
    int k = -1;
    for(int i = 0; i < 42; i++) {
        DateTime cur = new DateTime(date.year, date.month, date.day + i);
        if (i%7==0) k++;
        if(list.length <= k)
            list.add(new List());
        list[k].add(cur);
        if(cur.compareTo(end) == 0)
            break;
    }
    return list;
}