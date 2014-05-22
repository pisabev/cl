library vistemplates;

import 'dart:html';

main() {

    var el_outer = new DivElement()..className = 'outer';
    var el = new DivElement()..className = 'inner';
    el_outer.append(el);
    document.body.append(el_outer);

    //print(el_outer.getComputedStyle().getPropertyValue('padding-top'));
    print(el.offsetHeight);

}