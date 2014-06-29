library test;

import 'dart:async';
import 'package:cjs/app.dart' as cl_app;
import 'package:cjs/forms.dart' as cl_form;
import 'package:cjs/action.dart' as cl_action;
import 'package:cjs/gui.dart' as cl_gui;
import 'package:cjs/utils.dart' as cl_util;
import 'package:cjs/base.dart' as cl;
import 'package:intl/intl.dart';
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
      ap.setMenu([
            {'title':'ItemBuilder', 'key':'7', 'ref':'main', 'icon': 'product', 'desktop':true, 'action': ()=>ap.load('ItemBuilder', ()=>new Customer(ap))},
            {'title':'Editor', 'key':'1', 'ref':'main', 'icon': 'product', 'desktop':true, 'action': ()=>editor(ap)},
            {'title':'Tree', 'key':'2', 'ref':'main', 'action': ()=>tree(ap)},
            {'title':'DatePicker', 'key':'3', 'ref':'main', 'action': ()=>datePicker(ap)},
            {'title':'DatePickerRange', 'key':'4', 'ref':'main', 'action': ()=>datePickerRange(ap)},
            {'title':'Tab', 'key':'5', 'ref':'main', 'action': ()=>ap.load('Tab', ()=>new Tab())},
            {'title':'Test', 'key':'5', 'ref':'main', 'action': ()=>ap.load('Test', ()=>new DatePicker())},
            {'title':'Grid', 'key':'5', 'ref':'main', 'action': ()=>ap.load('grid', ()=>new Grid())},
            {'title':'GridData', 'key':'6', 'ref':'main', 'action': ()=>ap.load('gridData', ()=>new GridData())},
        ]);
      //ap.set(set);
}

class Tab extends cl_app.Item {
    Map w = {'title': 'Tab', 'width': 500, 'height': 500};

    Tab() {
        var tab = new cl_gui.Tab();
        var grid = new cl_form.GridForm(new cl_form.Form());
        grid.addHook(cl_form.Data.hook_value, ()=>window.alert('sdsd'));
        tab.addTab(1, 'first', grid);
        tab.addTab(2, 'second', new DivElement());
        tab.activeTab(1);
        grid.addRow(['Title', new cl_form.Input().setName('text').setRequired(true)]);
        grid.addRow(['Date', new cl_form.InputDate().setName('date')]);
        grid.addRow(['DateRange', new cl_form.InputDateRange().setName('date_range')]);
        grid.addRow(['Upload', new cl_action.FileUploader().setTitle('upload').setName('ddd').setUpload('sdsdsdsdsd')]);
        grid.addRow(['Button', new cl_action.Button().setTitle('Press').setName('sdsd').addAction(
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
        wapi = new cl_app.WinApp(ap);
        wapi.load(w, this);
        wapi.win.getContent()
            ..append(tab)
            ..addHookLayout(tab);
        wapi.render();
    }
}

class TestCell extends cl_form.RowDataCell {

    TestCell(grid, row, cell, object) : super(grid, row, cell, object);

    render() {
        cell.innerHtml = '$object';
    }

}
class Grid extends cl_app.Item {
	Map w = {'title': 'Grid', 'width': 500, 'height': 500};
    Grid() {
		var grid = new cl_form.GridList();
        grid.initHeader([
            new cl_form.GridColumn('product')
                ..title = 'Product'
                ..filter = new cl_form.Input()
                ..sortable = true
                ..width = '100px',
            new cl_form.GridColumn('test')
                ..title = 'Group'
                ..type = (grid, row, cell, object) => new TestCell(grid, row, cell, object)
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
        wapi = new cl_app.WinApp(ap);
        wapi.load(w, this);
		wapi.win.getContent()
			..append(grid);
		wapi.render();
	}
}

class GridData extends cl_app.Item {
    Map w = {'title': 'Grid', 'width': 500, 'height': 500};
    GridData() {
        var grid = new cl_form.GridData();
        grid.num = true;
        //grid.drag = true;
        grid.initHeader([
            new cl_form.GridColumn('product')
                ..title = 'Product'
                ..filter = new cl_form.Input()
                ..sortable = true,
            new cl_form.GridColumn('test')
                ..title = 'Quantity'
                ..width = '100px'
                ..type = ((grid, row, cell, object) => new TestCell(grid, row, cell, object))
                ..selector = new cl_form.Selector(grid)

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
        wapi = new cl_app.WinApp(ap);
        wapi.load(w, this);
        wapi.win.getContent()
            ..append(grid);
        wapi.render();
    }
}


class DatePicker extends cl_app.Item {
	Map w = {'title': 'DatePicker', 'width': 250, 'height': 280};

	DatePicker(){
		var d = new cl_gui.DatePicker((d)=>window.console.log(d.toString()));
		var date = new DateTime.now();
		d.set(date.year, date.month, 10);
        wapi = new cl_app.WinApp(ap);
        wapi.load(w, this);
		wapi.win.getContent().append(d);
		wapi.render();
	}
}

editor(cl_app.Application ap) {
    ap.server_call = (contr, obj, func, load) {
        print('server call - $contr [$obj]');
        if (contr == '/directory/list') {
            func({
                'data' : [{
                    'd': {
                        'id':2, 'type': 'folder', 'value':'electronics', 'loadchilds': false
                    },
                    'p': 'item',
                    'r': 'ref1'
                },
                {
                    'd': {
                        'id':3, 'type': 'folder', 'value':'laptops', 'loadchilds': false
                    },
                    'p': 'item',
                    'r': 'ref2'
                },
                {
                    'd': {
                        'id':4, 'type': 'folder', 'value':'laptopsinner', 'loadchilds': false
                    },
                    'p': 'ref2',
                    'r': 'ref1'
                }],
                'meta':''
            });
        } else {
            func({
            });
        }
    };
	cl_app.Win win = new cl_app.Win(ap.desktop);
	win.setTitle('Editor');
	win.render(700, 500, 200, 200);
    win.setZIndex(500);

	var editor = new cl_form.Editor(ap);
	win.getContent()
		..append(editor)
		..addHookLayout(editor);

	win.initLayout();
}

tree(cl_app.Application ap) {
	cl_app.Win win = new cl_app.Win(ap.desktop);
	win.setTitle('Tree');
	win.render(500, 500, 200, 200);
	win.initLayout();
    cl_gui.TreeBuilder tree;
	tree = new cl_gui.TreeBuilder({
		'value': 'tree',
		'id':1,
		'icons': {
			'article_products': 'article',
			'product_group': 'group',
			'product_default' :'product'
		},
        'checkObj': ['2:product_group'],
		'action': (_) {},
        'actionCheck' :(t) {
            print(tree.getChecked());
        },
		'load': (renderer, item) {
			renderer(item, {
				'data': [{
					'd': {'id':2, 'type': 'product_group', 'value':'electronics', 'loadchilds': false},
					'p': 'item',
					'r': 'ref1'
					},
                {
                    'd': {'id':3, 'type': 'product_group', 'value':'laptops', 'loadchilds': false},
                    'p': 'item',
                    'r': 'ref2'
                },
                {
                    'd': {'id':4, 'type': 'product_group', 'value':'laptopsinner', 'loadchilds': false},
                    'p': 'ref2',
                    'r': 'ref1'
                }],
				'meta':''
			});
		}
	});
    tree.refreshTree();
	tree.appendTo(win.getContent());
}

class Customer extends ItemBuilder {
    var contr_get = '';
    var contr_save = '';
    var contr_del = '';
    var w = {
        'title': (id) => 'Title',
        'icon': 'customer', 'width': 800, 'height': 500
    };

    Customer(ap, [id = 0]) : super (ap, id);

    setDefaults () {
        form.getElement('active').setValue(1,true);
        form.getElement('name').focus();
    }

    setUI () {
        var t1 = createTab(1, 'Base');
        var t2 = createTab(2, 'Address');
        var t3 = createTab(3, 'Invoice');
        activeTab(1);

        t1.addRow(['Active',new cl_form.Check().setName('active').setContext('customer')]);
        t1.addRow(['Name',new cl_form.Input().setName('name').setRequired(true).setContext('customer_data')]);
        t1.addRow(['Phone',new cl_form.Input().setName('phone').setContext('customer_data')]);
        t1.addRow(['Email',new cl_form.Input().setName('mail').setContext('customer_data')]);
        t1.addRow(['New_password',new cl_form.Input().setName('password').setContext('customer_data')]);

        t2.addRow(['City',new cl_form.Input().setName('city').setContext('customer_data')]);
        t2.addRow(['Post_code',new cl_form.Input().setName('post').setContext('customer_data')]);
        t2.addRow(['Address',new cl_form.Input().setName('address').setContext('customer_data')]);

        t3.addRow(['Company',new cl_form.Input('int').setName('invoice_firm').setContext('customer_data')]);
        t3.addRow(['Address',new cl_form.Input('float').setName('invoice_address').setContext('customer_data')]);
        t3.addRow(['VAT',new cl_form.Input(cl_form.InputField.INT).setName('invoice_uid').setContext('customer_data')]);
        t3.addRow(['VAT2',new cl_form.Input().addValidation((e) {
            return new Future.value(false);
        }).setName('invoice_uid_vat').setContext('customer_data')]);

    }
}

gridList(cl_app.Application ap) {
	cl_app.Win win = new cl_app.Win(ap.desktop);
	win.setTitle('Calendar');
	win.render(500, 500, 200, 200);
	win.initLayout();

	cl_form.GridList grid = new cl_form.GridList();
	grid.initHeader([
		{'title':'header', 'key':'key1', 'width':'100%'},
		{'title':'header2', 'key':'key2'},
	]);
	grid.renderIt([{'key1': 12, 'key2': 32}]);
	grid.appendTo(win.getContent());
	grid.fillParent();
}

lang(cl_app.Application ap) {
	cl_app.Win win = new cl_app.Win(ap.desktop);
	win.setTitle('Language');

	List language = [
		{'language_id':1, 'code':'bg'},
		{'language_id':2, 'code':'en'},
		{'language_id':4, 'code':'ch'}
	];
	cl_form.LangInput lang = new cl_form.LangInput(language).setStyle({'margin':'5px','float':'left'});
	win.getContent().append(lang);
	cl_action.Button b = new cl_action.Button().setTitle('Value').setStyle({'margin':'5px'})
		.addAction((e) => window.console.log(lang.getValue().toString()));
	win.getContent().append(b);
	cl_form.Input lang2 = new cl_form.LangInput(language).setStyle({'margin':'5px','float':'left'});
	win.getContent().append(lang2);
	win.render(300, 280);
	win.initLayout();
}

datePicker (cl_app.Application ap) {
	cl_app.Win win = new cl_app.Win(ap.desktop);
	var d = new cl_gui.DatePicker((d)=>window.console.log(d.toString()));
	var date = new DateTime.now();
	d.set(date.year, date.month, 10);
	win.setTitle('Calendar');
	win.getContent().append(d);
	win.render(250, 280, 100, 100);
	win.initLayout();
}

datePickerRange (cl_app.Application ap) {
	cl_app.Win win = new cl_app.Win(ap.desktop);
	var d = new cl_gui.DatePickerRange((d)=>window.console.log(d.toString()));
	var date1 = new DateTime.now();
	var date2 = new DateTime.now();
	d.set([date1, date2]);
	win.setTitle('Calendar Range');
	win.getContent().append(d);
	win.render(435, 325, 100, 100);
	win.initLayout();
}



/*for(int i=0; i<10; i++) {
cl_app.Win win = new cl_app.Win(ap.desktop);
win.setTitle('Title' + i.toString());
win.render(200, 200, (i + 1)*10, (i + 1)*10);
win.initLayout();
}

cl_app.Win win = new cl_app.Win(ap.desktop);
win.setTitle('Title');
win.render(500, 500);
win.initLayout();

cl_form.Input i = new cl_form.Input(cl_form.InputField.INT).setStyle({'margin':'10px'});
i.addHook('hook_value', () => window.console.log('hook_value - ' + i.getName() + i.getValue().toString()));
i.setName('el');
i.setValue(10);
i.disable();

cl_form.TextArea a = new cl_form.TextArea();
a.setValue('sdsdsdsd');
window.console.log(i.getValue() is int);

cl_form.Check c = new cl_form.Check();


cl_form.Select s = new cl_form.Select();
s.addOption(1, 'first');
s.addOption(2, 'second');
s.addHook('hook_value', () => window.console.log('hook_value - ' + s.getValue().toString()));

win.getContent().append(i);
win.getContent().append(a);
win.getContent().append(c);
win.getContent().append(s);
cl_action.Button b = new cl_action.Button('name').setTitle('button');
win.getContent().append(b);

var inpd = new cl_form.InputDate();
win.getContent().append(inpd);

var inpdr = new cl_form.InputDateRange();
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