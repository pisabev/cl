import 'package:cjs/app.dart' as app;
import 'package:cjs/forms.dart' as forms;
import 'package:cjs/action.dart' as action;
import 'package:cjs/gui.dart' as gui;
import 'package:cjs/utils.dart';
import 'package:cjs/base.dart' as base;
import 'package:intl/intl.dart';
import 'dart:html';

var ap = new app.Application();
main() {
      var set = {
          'user': 'user',
          'menu': {'title': 'Menu', 'icon': 'user'},
          'menu_left': [
              {'title':'Editor', 'key':'1', 'ref':'main', 'action': ()=>editor(ap)},
              {'title':'Tree', 'key':'2', 'ref':'main', 'action': ()=>tree(ap)},
              {'title':'DatePicker', 'key':'3', 'ref':'main', 'action': ()=>datePicker(ap)},
              {'title':'DatePickerRange', 'key':'4', 'ref':'main', 'action': ()=>datePickerRange(ap)},
              {'title':'Tab', 'key':'5', 'ref':'main', 'action': ()=>ap.load('Tab', ()=>new Tab())},
              {'title':'Test', 'key':'5', 'ref':'main', 'action': ()=>ap.load('Test', ()=>new DatePicker())},
              {'title':'Grid', 'key':'5', 'ref':'main', 'action': ()=>ap.load('grid', ()=>new Grid())},
              {'title':'GridData', 'key':'6', 'ref':'main', 'action': ()=>ap.load('gridData', ()=>new GridData())},
          ],
          'menu_right': [
              {'title': 'Settings', 'action': (){}}
          ]
      };
      ap.set(set);
}

class Tab extends app.Item {
    Map w = {'title': 'Tab', 'width': 500, 'height': 500};

    Tab() {
        var tab = new gui.Tab();
        var grid = new forms.GridForm(new forms.Form());
        grid.addHook(forms.DataElement.hook_value, ()=>window.alert('sdsd'));
        tab.addTab(1, 'first', grid);
        tab.addTab(2, 'second', new DivElement());
        tab.activeTab(1);
        grid.addRow(['Title', new forms.Input().setName('text').setRequired(true)]);
        grid.addRow(['Date', new forms.InputDate().setName('date')]);
        grid.addRow(['DateRange', new forms.InputDateRange().setName('date_range')]);
        grid.addRow(['Upload', new action.FileUploader().setTitle('upload').setName('ddd').setUpload('sdsdsdsdsd')]);
        grid.addRow(['Button', new action.Button().setTitle('Press').setName('sdsd').addAction(
                (e) {
                var req = grid.form.getRequired();
                if (req.length > 0) {
                    req.first.focus();
                    return false;
                }
                window.console.log(grid.getValue().toString());
            }
        )]);
        grid.setValue({'text':'dsds', 'date': '2013-12-22', 'date_range': ['22/12/2013', 'null']});
        wapi = new app.WinApp(ap);
        wapi.load(w, this);
        wapi.win.getContent()
            ..append(tab)
            ..addHookLayout(tab);
        wapi.render();
    }
}

class TestCell extends forms.RowDataCell {

    TestCell(cell, object) : super(cell, object);

    render() {
        cell.innerHtml = '$object';
    }

}
class Grid extends app.Item {
	Map w = {'title': 'Grid', 'width': 500, 'height': 500};
    Grid() {
		var grid = new forms.GridList();
        grid.initHeader([
            new forms.GridColumn('product')
                ..title = 'Product'
                ..filter = new forms.Input()
                ..sortable = true
                ..width = '100px',
            new forms.GridColumn('test')
                ..title = 'Group'
                ..type = (cell, object) => new TestCell(cell, object)
        ]);
        var obj = {'product': 'sdsds', 'test':2, 'hidden': 4};
        var obj1 = {'product': 'sdsds', 'test':2, 'hidden': 4};
        var obj2 = {'product': 'sdsds', 'test':2, 'hidden': 4};
        var obj3 = {'product': 'sdsds', 'test':2, 'hidden': 4};
        var obj4 = {'product': 'sdsds', 'test':2, 'hidden': 4};
        var obj5 = {'product': 'sdsds', 'test':2, 'hidden': 4};
        var obj6 = {'product': 'sdsds', 'test':2, 'hidden': 4};
        var obj7 = {'product': 'sdsds', 'test':2, 'hidden': 4};
        grid.renderIt([
            obj,
            obj1,
            obj2,
            obj3,
            obj4,
            obj5,
            obj6,
            obj7,
        ]);
        print(obj);
        wapi = new app.WinApp(ap);
        wapi.load(w, this);
		wapi.win.getContent()
			..append(grid);
		wapi.render();
	}
}

class GridData extends app.Item {
    Map w = {'title': 'Grid', 'width': 500, 'height': 500};
    GridData() {
        var grid = new forms.GridData();
        grid.num = true;
        //grid.drag = true;
        grid.initHeader([
            new forms.GridColumn('product')
                ..title = 'Product'
                ..filter = new forms.Input()
                ..sortable = true,
            new forms.GridColumn('test')
                ..title = 'Quantity'
                ..width = '100px'
                ..type = ((cell, object) => new TestCell(cell, object))
                ..selector = new forms.Selector(grid)

        ]);
        var obj = {'product': 'wsd', 'test':2, 'hidden': 4};
        var obj1 = {'product': 'sdsds', 'test':2, 'hidden': 4};
        var obj2 = {'product': 'sdsds', 'test':2, 'hidden': 4};
        var obj3 = {'product': 'sdsds', 'test':2, 'hidden': 4};
        var obj4 = {'product': 'sdsds', 'test':2, 'hidden': 4};
        var obj5 = {'product': 'sdsds', 'test':2, 'hidden': 4};
        var obj6 = {'product': 'sdsds', 'test':2, 'hidden': 4};
        var obj7 = {'product': 'sdsds', 'test':2, 'hidden': 4};
        grid.renderIt([
            obj,
            obj1,
            obj2,
            obj3,
            obj4,
            obj5,
            obj6,
            obj7,
        ]);
        print(grid.getValue(true));
        wapi = new app.WinApp(ap);
        wapi.load(w, this);
        wapi.win.getContent()
            ..append(grid);
        wapi.render();
    }
}


class DatePicker extends app.Item {
	Map w = {'title': 'DatePicker', 'width': 250, 'height': 280};

	DatePicker(){
		var d = new gui.DatePicker((d)=>window.console.log(d.toString()));
		var date = new DateTime.now();
		d.set(date.year, date.month, 10);
        wapi = new app.WinApp(ap);
        wapi.load(w, this);
		wapi.win.getContent().append(d);
		wapi.render();
	}
}

editor(app.Application ap) {
	app.Win win = new app.Win(ap.desktop);
	win.setTitle('Editor');
	win.render(500, 500, 200, 200);

	var editor = new forms.Editor();
	win.getContent()
		..append(editor)
		..addHookLayout(editor);

	win.initLayout();
}

tree(app.Application ap) {
	app.Win win = new app.Win(ap.desktop);
	win.setTitle('Tree');
	win.render(500, 500, 200, 200);
	win.initLayout();

	gui.TreeBuilder tree = new gui.TreeBuilder({
		'value': 'tree',
		'type': 'article_products',
		'id':1,
		'icons': {
			'article_products': 'article',
			'product_group': 'group',
			'product_default' :'product'
		},
		'action': (_) {},
		'load': (renderer, item) {
			renderer(item, {
				'data': [{
					'd': {'id':2, 'type': 'product_group', 'value':'electronics', 'loadchilds': false},
					'p': 'item',
					'r': 'ref1'
					}],
				'meta':''
			});
		}
	});
	tree.appendTo(win.getContent());
}

gridList(app.Application ap) {
	app.Win win = new app.Win(ap.desktop);
	win.setTitle('Calendar');
	win.render(500, 500, 200, 200);
	win.initLayout();

	forms.GridList grid = new forms.GridList();
	grid.initHeader([
		{'title':'header', 'key':'key1', 'width':'100%'},
		{'title':'header2', 'key':'key2'},
	]);
	grid.renderIt([{'key1': 12, 'key2': 32}]);
	grid.appendTo(win.getContent());
	grid.fillParent();
}

lang(app.Application ap) {
	app.Win win = new app.Win(ap.desktop);
	win.setTitle('Language');

	List language = [
		{'language_id':1, 'code':'bg'},
		{'language_id':2, 'code':'en'},
		{'language_id':4, 'code':'ch'}
	];
	forms.LangInput lang = new forms.LangInput(language).setStyle({'margin':'5px','float':'left'});
	win.getContent().append(lang);
	action.Button b = new action.Button().setTitle('Value').setStyle({'margin':'5px'})
		.addAction((e) => window.console.log(lang.getValue().toString()));
	win.getContent().append(b);
	forms.Input lang2 = new forms.LangInput(language).setStyle({'margin':'5px','float':'left'});
	win.getContent().append(lang2);
	win.render(300, 280);
	win.initLayout();
}

datePicker (app.Application ap) {
	app.Win win = new app.Win(ap.desktop);
	var d = new gui.DatePicker((d)=>window.console.log(d.toString()));
	var date = new DateTime.now();
	d.set(date.year, date.month, 10);
	win.setTitle('Calendar');
	win.getContent().append(d);
	win.render(250, 280, 100, 100);
	win.initLayout();
}

datePickerRange (app.Application ap) {
	app.Win win = new app.Win(ap.desktop);
	var d = new gui.DatePickerRange((d)=>window.console.log(d.toString()));
	var date1 = new DateTime.now();
	var date2 = new DateTime.now();
	d.set([date1, date2]);
	win.setTitle('Calendar Range');
	win.getContent().append(d);
	win.render(435, 325, 100, 100);
	win.initLayout();
}



/*for(int i=0; i<10; i++) {
app.Win win = new app.Win(ap.desktop);
win.setTitle('Title' + i.toString());
win.render(200, 200, (i + 1)*10, (i + 1)*10);
win.initLayout();
}

app.Win win = new app.Win(ap.desktop);
win.setTitle('Title');
win.render(500, 500);
win.initLayout();

forms.Input i = new forms.Input(forms.InputField.INT).setStyle({'margin':'10px'});
i.addHook('hook_value', () => window.console.log('hook_value - ' + i.getName() + i.getValue().toString()));
i.setName('el');
i.setValue(10);
i.disable();

forms.TextArea a = new forms.TextArea();
a.setValue('sdsdsdsd');
window.console.log(i.getValue() is int);

forms.Check c = new forms.Check();


forms.Select s = new forms.Select();
s.addOption(1, 'first');
s.addOption(2, 'second');
s.addHook('hook_value', () => window.console.log('hook_value - ' + s.getValue().toString()));

win.getContent().append(i);
win.getContent().append(a);
win.getContent().append(c);
win.getContent().append(s);
action.Button b = new action.Button('name').setTitle('button');
win.getContent().append(b);

var inpd = new forms.InputDate();
win.getContent().append(inpd);

var inpdr = new forms.InputDateRange();
win.getContent().append(inpdr);

lang(ap);

datePicker(ap);
datePickerRange(ap);
gridList(ap);
tree(ap);
editor(ap);

window.console.log('last-month-range ' + Calendar.getLastMonthRange().toString());
window.console.log('last-year-range ' + Calendar.getLastYearRange().toString());
window.console.log('this-year-range ' + Calendar.getThisYearRange().toString());
window.console.log('last-month-range ' + Calendar.getLastMonthRange().toString());
window.console.log('this-month-range ' + Calendar.getThisMonthRange().toString());
window.console.log('last-week-range ' + Calendar.getLastWeekRange().toString());
window.console.log('this-week-range ' + Calendar.getThisWeekRange().toString());
window.console.log('yestarday-range ' + Calendar.getYesterdayRange().toString());
window.console.log('substring ' + Calendar.getDayString(new DateTime.now()).toString());
window.console.log('substring ' + Calendar.getMonthString(new DateTime.now()).toString());*/