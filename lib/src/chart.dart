part of chart;

testSVG(dom) {
    var d = new CJSElement(new DivElement()).appendTo(dom).setClass('ui-gadget-outer');
    var h2 = new CJSElement(new HeadingElement.h2()).appendTo(d);
    var i = new CJSElement(new DivElement()).appendTo(d).setClass('ui-gadget-inner');
    h2.dom.text = 'Title';

	var chart = new Chart(i, 450, 300);
	chart.setData([['x',200],['x2',70], ['x3',230], ['x4',60], ['x4',50], ['x4',20], ['x',1000], ['x2',70], ['x3',230], ['x4',60], ['x4',50], ['x4',20], ['x4',20], ['x',1000], ['x2',70], ['x3',230], ['x4',60], ['x4',50],['x3',230], ['x4',60], ['x4',50], ['x4',20],['x3',230], ['x4',60], ['x4',50], ['x4',20]]);
	chart.initGraph();
	chart.renderGrid();
	chart.renderGraph();

    var d1 = new CJSElement(new DivElement()).appendTo(dom).setClass('ui-gadget-outer');
    var h21 = new CJSElement(new HeadingElement.h2()).appendTo(d1);
    var i1 = new CJSElement(new DivElement()).appendTo(d1).setClass('ui-gadget-inner');
    h21.dom.text = 'Title';

	var pie = new Pie(i1, 450, 300);
    pie.initDisplay();
	pie.setData([['Петър Събев',70], ['Йордан Иванов',50], ['Анастасия',40]]);
	pie.draw();

   /* var d3 = new CJSElement(new DivElement()).appendTo(dom).setClass('ui-gadget-outer');
    var h23 = new CJSElement(new HeadingElement.h2()).appendTo(d3);
    var i3 = new CJSElement(new DivElement()).appendTo(d3).setClass('ui-gadget-inner');
    h23.dom.text = 'Title';

    var chart2 = new Chart(i3, 450, 300);
    chart2.setData([['x',200],['x2',70], ['x3',230], ['x4',60], ['x4',50], ['x4',20], ['x',1000], ['x2',70], ['x3',230], ['x4',60], ['x4',50], ['x4',20], ['x4',20], ['x',1000], ['x2',70], ['x3',230], ['x4',60], ['x4',50],['x3',230], ['x4',60], ['x4',50], ['x4',20],['x3',230], ['x4',60], ['x4',50], ['x4',20]]);
    chart2.initGraph();
    chart2.renderGrid();
    chart2.renderGraph();*/
    testSvg2(dom);
}
testSvg2(dom) {
    var d = new CJSElement(new DivElement()).appendTo(dom).setClass('ui-gadget-outer');
    var h2 = new CJSElement(new HeadingElement.h2()).appendTo(d);
    var i = new CJSElement(new DivElement()).appendTo(d).setClass('ui-gadget-inner');
    h2.dom.text = 'Title';

    var chart = new Chart(i, 450, 300);
    chart.setData([['x',200],['x2',70], ['x3',230], ['x4',60], ['x4',50], ['x4',20], ['x',1000], ['x2',70], ['x3',230], ['x4',60], ['x4',50], ['x4',20], ['x4',20], ['x',1000], ['x2',70], ['x3',230], ['x4',60], ['x4',50],['x3',230], ['x4',60], ['x4',50], ['x4',20],['x3',230], ['x4',60], ['x4',50], ['x4',20]]);
    chart.initGraph();
    chart.renderGrid();
    chart.renderGraph();

    var d1 = new CJSElement(new DivElement()).appendTo(dom).setClass('ui-gadget-outer');
    var h21 = new CJSElement(new HeadingElement.h2()).appendTo(d1);
    var i1 = new CJSElement(new DivElement()).appendTo(d1).setClass('ui-gadget-inner');
    h21.dom.text = 'Title';

    var pie = new Pie(i1, 450, 300);
    pie.initDisplay();
    pie.setData([['Петър Събев',70], ['Йордан Иванов',50], ['Анастасия',40]]);
    pie.draw();
/*
    var d3 = new CJSElement(new DivElement()).appendTo(dom).setClass('ui-gadget-outer');
    var h23 = new CJSElement(new HeadingElement.h2()).appendTo(d3);
    var i3 = new CJSElement(new DivElement()).appendTo(d3).setClass('ui-gadget-inner');
    h23.dom.text = 'Title';

    var chart2 = new Chart(i3, 450, 300);
    chart2.setData([['x',200],['x2',70], ['x3',230], ['x4',60], ['x4',50], ['x4',20], ['x',1000], ['x2',70], ['x3',230], ['x4',60], ['x4',50], ['x4',20], ['x4',20], ['x',1000], ['x2',70], ['x3',230], ['x4',60], ['x4',50],['x3',230], ['x4',60], ['x4',50], ['x4',20],['x3',230], ['x4',60], ['x4',50], ['x4',20]]);
    chart2.initGraph();
    chart2.renderGrid();
    chart2.renderGraph();*/
}

class Chart {
	CJSElement container;
	int width =              0;
	int height =             0;
	SvgSvgElement svg;
	GElement graph, legend;
	int graph_count = 		 0;

	GElement label;
	AnimateTransformElement label_anim;
	AnimateElement label_anim_op;
	RectElement label_rect;
	TextElement label_text;
	String label_current =	 '0,0';
	int label_padding =	     10;
	int label_offset = 		 10;

	int graphOffsetTop =     15;
	int graphOffsetBottom =  50;
	int graphOffsetLeft =    15;
	int graphOffsetRight =   50;

	double crispOffset = 	 0.5;

	var graphStartX =        0;
	var graphStartY =        0;
	var graphEndX =          0;
	var graphEndY =          0;

	var graphWidth =         0;
	var graphHeight =        0;

	int minOffsetGridY =     60;
	int minOffsetGridX =     60;

	var gridCountY =         0;
	var gridCountX =         0;
	var gridOffsetY =        0;
	var gridOffsetX =        0;

	var highestY =           0;
	var gridRatioY =         1;
	var gridRatioX =         1;

	List data;

	Chart (this.container, [this.width, this.height]) {
        reset();
    }

    reset() {
        graph_count = 0;
        container.removeChilds();
        svg = new SvgSvgElement()
            ..setAttribute('width', '$width')
            ..setAttribute('height', '$height')
            ..setAttribute('class', 'ui-chart-grid');
        container.append(svg);
    }

    setData (List d) {
        var highest = highestY;
        var set = (d.length==1)? [['',0], d[0], ['',0]] : d;
        for (var i=0, l=set.length;i<l;i++) {
            if(set[i][1] == null)
                set[i][1] = 0;
            var cur = set[i][1];
            if (cur>highest) {
                highest=cur;
            }
        }
        data = set;
        highestY = highest;
    }

    initGraph () {
        var labelY_length = 40;
        graphOffsetLeft = (labelY_length<50)? 50 : labelY_length;
        graphStartX = graphOffsetLeft + crispOffset;
        graphStartY = graphOffsetTop + crispOffset;
        graphEndX = width - graphOffsetRight + crispOffset;
        graphEndY = height - graphOffsetBottom + crispOffset;
        graphWidth = graphEndX - graphStartX;
        graphHeight = graphEndY - graphStartY;

		var group_transform = new GElement()
		   	..setAttribute('transform', 'translate($graphStartX,$graphEndY)');
        var group_scale = new GElement()
        	..setAttribute('transform', 'scale(1, -1)');
    	group_transform.append(group_scale);
    	svg.append(group_transform);
    	graph = group_scale;
    	legend = new GElement()..setAttribute('class', 'legend');
    	svg.append(legend);

        _calcGridYCountRatio();

        if(gridCountY > 0)
            gridOffsetY = graphHeight/gridCountY;
        _calcGridX();
    }

    renderGrid () {
    	var border = new RectElement();
    	border.setAttribute('class', 'border');
    	border.setAttribute('width', '$graphWidth');
    	border.setAttribute('height', '$graphHeight');
    	graph.append(border);
    	for (int i = 0; i <= gridCountY; i++) {
    		var y = (i * gridOffsetY).floor();
            var l = new LineElement()
            	..setAttribute('x1','0')
            	..setAttribute('y1','$y')
            	..setAttribute('x2','$graphWidth')
            	..setAttribute('y2','$y');
            graph.append(l);
            _createLabelY(i * gridRatioY, graphStartX, graphEndY - y);
        }
    	for (int i = 0; i <= gridCountX; i++) {
            var x = (i * gridOffsetX).floor();
            var l = new LineElement()
            	..setAttribute('x1','$x')
            	..setAttribute('y1','0')
            	..setAttribute('x2','$x')
            	..setAttribute('y2','$graphHeight');
            graph.append(l);
            _createLabelX(data[i * gridRatioX][0], graphStartX + x, graphEndY);
        }
    }

    renderGraph () {
    	_createLabel();
		String classname = 'path${++graph_count}';
    	var group = new GElement()..setAttribute('class', classname);

    	var path = new PathElement();
    	StringBuffer sb = new StringBuffer();
    	sb.write('M 0,0');

    	StringBuffer sb_anim_from = new StringBuffer();
    	var anim = new AnimateElement();
    	sb_anim_from.write('M 0,0');

    	List points = new List();
    	bool add_points = (data.length * 6 < graphWidth);
    	for(int i = 0; i < data.length; i++) {
    		var y = (gridRatioY == 0)? 0 : (data[i][1] / gridRatioY) * gridOffsetY;
    		var x = i * (gridOffsetX/gridRatioX);
    		sb.write(' $x,$y');
    		sb_anim_from.write(' $x, 0');
    		if(add_points)
    			points.add(_createPoint('${data[i][0]} - ${data[i][1]}', classname, x, y));
    	}
    	sb.write(' $graphWidth,0 z');
    	path.setAttribute('d', sb.toString());

    	sb_anim_from.write(' $graphWidth,0 z');
    	anim.setAttribute('id', 'anim');
    	anim.setAttribute('attributeName', 'd');
        anim.setAttribute('from', sb_anim_from.toString());
        anim.setAttribute('to', sb.toString());
        anim.setAttribute('dur', '0.2s');

        path.append(anim);

    	group.append(path);
    	points.forEach((point) => group.append(point));

    	graph.append(group);
    }

    _calcGridYCountRatio () {
        if(highestY > 0) {
            gridCountY = (graphHeight/minOffsetGridY).ceil();
            var step = highestY/gridCountY;
            var digits = (log(step) / log(10)).ceil();
            var division = pow(10, digits-1);
            var roundup = ((step / division).ceil() > 0)? (step / division).ceil() : 0;
            gridRatioY = roundup * division;
        } else {
            gridCountY = 0;
            gridRatioY = 0;
        }
    }

    _calcGridX () {
        var gridCountX = data.length - 1;
        gridCountX = (gridCountX >= 1)? gridCountX : 1;
        var gridRatioX = 1;
        while ((graphWidth / (gridCountX / gridRatioX)) / minOffsetGridX < 1) {
            gridRatioX +=1;
        }
        this.gridRatioX = gridRatioX;
        this.gridCountX = gridCountX/gridRatioX;
        this.gridOffsetX = graphWidth/this.gridCountX;
    }

    _createLabelY (value, x, y) {
        var label = new TextElement()
            ..setAttribute('x', '${x - 5}')
            ..setAttribute('y', '${y}')
            ..setAttribute('text-anchor', 'end')
            ..text = '$value';
        legend.append(label);
    }

    _createLabelX (value, x, y) {
        var arr = value.split(' ');
        if(arr.length == 2) {
            var label = new TextElement()
                ..setAttribute('x', '${x}')
                ..setAttribute('y', '${y + 15}')
                ..text = '${arr[0]}';
            legend.append(label);
            label = new TextElement()
                ..setAttribute('x', '${x}')
                ..setAttribute('y', '${y + 28}')
                ..text = '${arr[1]}';
            legend.append(label);
        } else if(arr.length == 3) {
            var label = new TextElement()
                ..setAttribute('x', '${x}')
                ..setAttribute('y', '${y + 15}')
                ..text = '${arr[0]} ${arr[1]}';
            legend.append(label);
            label = new TextElement()
                ..setAttribute('x', '${x}')
                ..setAttribute('y', '${y + 28}')
                ..text = '${arr[2]}';
            legend.append(label);
        } else {
            var label = new TextElement()
                ..setAttribute('x', '${x}')
                ..setAttribute('y', '${y + 15}')
                ..text = '$value';
            legend.append(label);
        }
    }

    _createLabel() {
    	label = new GElement()..setAttribute('class', 'current');
    	label.setAttribute('transform', 'translate(0,0)');
    	label_anim = new AnimateTransformElement()
	        ..setAttribute('attributeName', 'transform')
	        ..setAttribute('type', 'translate')
	        ..setAttribute('dur', '0.2s');
    	label_anim_op = new AnimateElement()
	        ..setAttribute('attributeName', 'opacity')
	        ..setAttribute('dur', '0.5s');
    	label.style.visibility = 'hidden';
    	label_rect = new RectElement();
    	label_rect.setAttribute('rx', '5');
    	label_rect.setAttribute('ry', '5');
        label_text = new TextElement();
        label.append(label_anim);
        label.append(label_anim_op);
        label.append(label_rect);
        label.append(label_text);
        legend.append(label);
    }

    _labelShow(value, String classname, x, y) {
    	label.style.visibility = '';
    	label_text.text = '$value';
    	var box = label_text.getBBox();
    	var rect_width = box.width + label_padding*2;
    	var rect_height = box.height + label_padding*2;
    	label_rect.setAttribute('class', classname);
    	label_rect.setAttribute('width', '$rect_width');
        label_rect.setAttribute('height', '$rect_height');
        label_text.setAttribute('x', '${label_padding}');
        label_text.setAttribute('y', '${box.height + label_padding - 3}');

        var offset_x = label_offset;
        if(x + label_offset + rect_width > graphEndX)
        	offset_x = (offset_x + rect_width)*-1;
        var offset_y = (rect_height + label_offset)*-1;
        if(y - label_offset - rect_height < graphStartY)
        	offset_y = (offset_y + rect_height)*-1;

        label_anim.setAttribute('from', '$label_current');
    	label_current = '${x + offset_x},${y + offset_y}';
    	label_anim.setAttribute('to', '$label_current');
    	label_anim.beginElement();
    	label_anim_op.setAttribute('from', '0');
    	label_anim_op.setAttribute('to', '1');
    	label_anim_op.beginElement();
    	label.setAttribute('transform', 'translate($label_current)');
    }

    _labelHide(e) {
    	label.style.visibility = 'hidden';
    }

    _createPoint(dynamic value, String classname, dynamic x, dynamic y) {
    	var circle = new CircleElement()
    		..setAttribute('cx', '$x')
    		..setAttribute('cy', '$y')
    		..onMouseOver.listen((e) => _labelShow(value, classname, x + graphStartX, graphEndY - y))
    		..onMouseOut.listen(_labelHide),
    		anim1 = new AnimateElement()
	        ..setAttribute('attributeName', 'r')
	        ..setAttribute('from', '0')
	        ..setAttribute('to', '3')
	        ..setAttribute('fill', 'freeze')
	        ..setAttribute('dur', '0.2s')
	        ..setAttribute('begin', 'anim.end'),
    		anim2 = new AnimateElement()
	        ..setAttribute('attributeName', 'r')
	        ..setAttribute('from', '3')
	        ..setAttribute('to', '5')
	        ..setAttribute('fill', 'freeze')
	        ..setAttribute('dur', '0.2s')
	        ..setAttribute('begin', 'mouseover'),
    		anim3 = new AnimateElement()
	        ..setAttribute('attributeName', 'r')
	        ..setAttribute('from', '5')
	        ..setAttribute('to', '3')
	        ..setAttribute('fill', 'freeze')
	        ..setAttribute('dur', '0.2s')
	        ..setAttribute('begin', 'mouseout');

    	circle.append(anim1);
    	circle.append(anim2);
    	circle.append(anim3);
    	return circle;
    }

}

class Pie {
	var container;
	SvgSvgElement svg;
	int width       = 0;
	int height      = 0;
	GElement graph;
	int segment_count = 0;

	Map center	  = new Map();
	int radius 	  = 0;
	int size      = 0;
	int legend_o  = 10;
	int legend_l  = 0;

    List segments = new List();
    List segmentAngles = new List();
    List segmentAnims = new List();
    List segmentLabels = new List();

	List data;
	double total  = 0.0;

	Pie(this.container, [int this.width, int this.height]) {
		svg = new SvgSvgElement()
        	..setAttribute('width', '$width')
        	..setAttribute('height', '$height')
        	..setAttribute('class', 'ui-chart-pie');
		graph = new GElement()
		   	..setAttribute('transform', 'translate(0.5,0.5)');
    	svg.append(graph);
		container.append(svg);
	}

    initDisplay () {
        var half = width / 2,
        size = min(height, half);
        legend_l = size + legend_o;
        radius = size / 2;
        center = {'x': radius, 'y': radius};
    }

	setData(List data) {
		this.data = data;
		total = 0.0;
        data.forEach((set) => total += set[1]);
        int i = 0;
        data.forEach((set) {
            var path = new PathElement();
            var classname = 'slice${++segment_count}';
            path.setAttribute('class', classname);
            graph.append(path);
            (path, num) {
                path.onMouseOver.listen((e) => _animateSegment(num, '1', '0.2'));
                path.onMouseOut.listen((e) => _animateSegment(num, '0.2', '1'));
            }(path, i);
            var anim = new AnimateElement()
                ..setAttribute('attributeName', 'opacity')
                ..setAttribute('fill', 'freeze');
            path.append(anim);

            var percentage = set[1]/total;
            var label_anim = _getLegend('${set[0]} - ${(percentage*100).toStringAsFixed(2)} %', classname, legend_l, i);
            i++;

            segmentAnims.add(anim);
            segmentLabels.add(label_anim);
            segments.add(path);
            segmentAngles.add(percentage * (PI*2));
        });
        if(segments.length == 1)
            segmentAngles[0] = 0.999 * (PI*2);
		return this;
	}

    draw() {
        int time = 0,
            step = 10,
            duration = 500;
        new Timer.periodic(new Duration(milliseconds: step), (t) {
            var v = EasingEngine.easeOutExponential(time += step, duration, 1, 0);
            _drawFrame(v);
            if(v >= 1)
                t.cancel();
        });
    }

    _drawFrame([rotateAnimation = 1]) {
        double startRadius = -PI/2;
        int length = data.length,
            i = 0;
        segmentAngles.forEach((segment) {
            var segmentAngle = rotateAnimation * segment,
                endRadius = startRadius + segmentAngle,
                largeArc = ((endRadius - startRadius) % (PI * 2)) > PI ? 1 : 0,
                startX = center['x'] + cos(startRadius) * radius,
                startY = center['y'] + sin(startRadius) * radius,
                endX = center['x'] + cos(endRadius) * radius,
                endY = center['y'] + sin(endRadius) * radius;
            startRadius += segmentAngle;

            segments[i++].setAttribute('d', "M ${startX} ${startY} A ${radius} ${radius} 0 $largeArc 1 ${endX} ${endY} L ${center['x']} ${center['y']} z");
        });
    }

	_animateSegment(int num, String from, String to) {
		for(int i = 0; i < segments.length; i++) {
			if(i != num) {
				var label = segmentLabels[i],
				    slice = segmentAnims[i];
				label
                    ..setAttribute('from', from)
				    ..setAttribute('to', to)
				    ..setAttribute('dur', '0.4s')
				    ..beginElement();
				slice
                    ..setAttribute('from', from)
				    ..setAttribute('to', to)
				    ..setAttribute('dur', '0.4s')
				    ..beginElement();
			}
		}
	}

	_getLegend(dynamic value, String classname, x, num) {
		var group = new GElement(),
		    rect = new RectElement(),
		    text = new TextElement(),
		    anim = new AnimateElement();

		group
            ..append(rect)
		    ..append(text)
		    ..append(anim)
            ..setAttribute('transform', 'translate($x, ${num*30})')
		    ..onMouseOver.listen((e) =>_animateSegment(num, '1', '0.2'))
		    ..onMouseOut.listen((e) => _animateSegment(num, '0.2', '1'));

		rect
            ..setAttribute('class', classname)
		    ..setAttribute('width', '20')
		    ..setAttribute('height', '20');

     	text
     	    ..setAttribute('x', '25')
     	    ..setAttribute('y', '14')
            ..text = value;

     	anim
     		..setAttribute('attributeName', 'opacity')
	        ..setAttribute('fill', 'freeze');

     	graph.append(group);
     	return anim;
	}

}