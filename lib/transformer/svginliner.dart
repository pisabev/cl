import 'package:barback/barback.dart';

import 'dart:async';
import 'package:path/path.dart' as path;

class SVGInliner extends Transformer {

    SVGInliner.asPlugin();

    final Map icons = {
        'main-icons': '#BBBBBB',
        'blackp-icons' : '#CDCDCD'
    };

    Future<bool> isPrimary(AssetId input) {
        return new Future.value(input.path.endsWith("-icons.css"));
    }

    Future apply(Transform transform) {
        return transform.primaryInput
        .readAsString()
        .then(_readIconCSSContent)
        .then((data) => _readSvgFilesContent(data, transform))
        .then((data) {
            var css_content = _buildFiles(data, transform);
            transform.addOutput(new Asset.fromString(transform.primaryInput.id, css_content));
        });
    }

    _buildFiles(List data, Transform transform) {
        List paths = new List();
        data.forEach((Map m) {
            if (m.containsKey('content')) {
                String s = m['content'];
                var match = new RegExp(r'<path\b[^>]*/>', multiLine: true, caseSensitive: false).firstMatch(s);
                var path = match[0]
                    .replaceAll(new RegExp(r'"', multiLine: true, caseSensitive: false), "'")
                    .replaceAll(new RegExp(r'\sfill\s*=\s*".*?"', multiLine: true, caseSensitive: false), "fill='#CDCDCD'");
                var lsb = new StringBuffer()
                    ..write("<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1' baseProfile='full' width='76' height='76' viewBox='0 0 76.00 76.00' xml:space='preserve'>")
                    ..write(path)
                    ..write('</svg>');
                paths.add(lsb.toString());
                m['declaration'] = 'background-image: url("data:image/svg+xml;utf8,${Uri.encodeFull(lsb.toString())}");';
            }
        });

        var sb_css = new StringBuffer();
        data.forEach((Map m) {
            sb_css.write('${m['classname']}{${m['declaration']}}\n');
        });
        return sb_css.toString();
    }

    _readSvgFilesContent(List data, Transform transform) {
        var list = new List();
        data.forEach((Map m) {
            if(m.containsKey('path') && m['path'] != null) {
                var aid = new AssetId(transform.primaryInput.id.package, path.normalize('${path.dirname(transform.primaryInput.id.path)}/${m['path']}'));
                list.add(
                    transform.hasInput(aid).then((tr) {
                        if(tr) {
                            return transform.readInputAsString(aid)
                            .then((d) {
                                m['content'] = d;
                                return true;
                            });
                        }
                    })
                );
            }
        });
        return Future.wait(list).then((_) => data);
    }

    _readIconCSSContent(String content) {
        List data = new List();
        content.split('\n').forEach((line) {
            if (line != '') {
                var d = new RegExp(r'(.*)?{(.*)?}', multiLine: true, caseSensitive: false).firstMatch(line);
                if(d != null) {
                    var classname = d[1].trim();
                    var declaration = d[2];
                    var p = new RegExp(r'url\((.*)?\)', multiLine: true, caseSensitive: false).firstMatch(d[2]);
                    var path = (p != null) ? p[1] : null;
                    data.add({
                        'classname': classname,
                        'declaration': declaration,
                        'path': path
                    });
                }
            }
        });
        return new Future.value(data);
    }
}