import 'package:barback/barback.dart';

import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;

class SVGSpriter extends Transformer {

    SVGSpriter.asPlugin();

    final Map icons = {
        'main-icons': '#AAAAAA',
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
        int offset = 76,
            offset_current = 0,
            icon_small = 24,
            icon_small_offset = 0,
            icon_big = 92,
            icon_big_offset = 0;
        data.forEach((Map m) {
            if (m.containsKey('content')) {
                String s = m['content'];
                var match = new RegExp(r'<path\b[^>]*/>', multiLine: true, caseSensitive: false).firstMatch(s);
                var path = match[0].replaceAll(new RegExp(r'\sfill\s*=\s*".*?"', multiLine: true, caseSensitive: false), '');
                var lsb = new StringBuffer()
                    ..write('<g transform="translate(0, ${offset_current})">\n')
                    ..write(path)
                    ..write('\n')
                    ..write('</g>\n');
                paths.add(lsb.toString());
                m['declaration'] = 'background-position: 0px -${icon_small_offset}px';
                m['declaration-big'] = 'background-position: 0px -${icon_big_offset}px';
                offset_current += offset;
                icon_small_offset += icon_small;
                icon_big_offset += icon_big;
            }
        });
        var fn = transform.primaryInput.id.path.split('/').last.split('.').first;
        var sb = new StringBuffer()
            ..write('<?xml version="1.0" encoding="utf-8"?>\n')
            ..write('<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n')
            ..write('<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" baseProfile="full" width="76" height="$offset_current" viewBox="0 0 76.00 $offset_current.00" xml:space="preserve">\n')
            ..write('<defs><style>path{fill:${icons[fn]};}</style></defs>\n')
            ..writeAll(paths)
            ..write('</svg>');
        var pathdir = path.dirname(transform.primaryInput.id.path);
        transform.addOutput(new Asset.fromString(new AssetId(transform.primaryInput.id.package, '${path.normalize(pathdir+'/../images')}/$fn.svg'), sb.toString()));

        var sb_css = new StringBuffer();
        data.forEach((Map m) {
            sb_css.write('.icon${m['classname']}{${m['declaration']}}\n');
            if(m.containsKey('declaration-big'))
                sb_css.write('.icon-big${m['classname']}{${m['declaration-big']}}\n');
        });
        sb_css.write('.icon:before{background-image:url(../images/$fn.svg);background-size:${icon_small}px ${icon_small_offset}px;}\n');
        sb_css.write('.icon-big:before{background-image:url(../images/$fn.svg);background-size:${icon_big}px ${icon_big_offset}px;}');
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