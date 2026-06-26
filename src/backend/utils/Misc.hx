package backend.utils;

import openfl.geom.Matrix;
import openfl.display.Shape;
import openfl.display.BitmapData;
import openfl.text.TextFormat;
import openfl.text.TextField;

using StringTools;

class Misc {
    public static function markdownToHTMLText(markdown:String):String {
        var result = [];
        var inList = false;

        var h6 = ~/^######\s+(.*)/;
        var h5 = ~/^#####\s+(.*)/;
        var h4 = ~/^####\s+(.*)/;
        var h3 = ~/^###\s+(.*)/;
        var h2 = ~/^##\s+(.*)/;
        var h1 = ~/^#\s+(.*)/;
        var list = ~/^\s*[-*]\s+(.*)/;

        var boldItalic = ~/\*\*\*(.+?)\*\*\*/g;
        var bold = ~/\*\*(.+?)\*\*/g;
        var italic = ~/\*(.+?)\*/g;
        var strike = ~/~~(.+?)~~/g;
        var code = ~/`([^`]+)`/g;

        var link = ~/\[([^\]]+)\]\(([^)]+)\)/gs;

        markdown = link.map(markdown, (e) -> {
            var linkText = ~/\s+/g.replace(e.matched(1), ' ').trim();
            var linkUrl = ~/\s+/g.replace(e.matched(2), ' ').trim();
            return '<font color="#F6871F"><i><u><a href="${linkUrl}">${linkText}</a></u></i></font>';
        });

        for (line in markdown.split('\n')) {
            line = line.rtrim();
            var trimmed = line.trim();

            if (trimmed == '' || trimmed == '---' || trimmed == '***' || trimmed == '*') continue;

            if (line.endsWith('\\'))
                line = line.substr(0, line.length - 1);

            var isList = false;
            var headerLevel = 0;
            var content = line;

            if (list.match(line)) {
                isList = true;
                content = list.matched(1);
            } else if (h6.match(line)) { headerLevel = 6; content = h6.matched(1); }
            else if (h5.match(line)) { headerLevel = 5; content = h5.matched(1); }
            else if (h4.match(line)) { headerLevel = 4; content = h4.matched(1); }
            else if (h3.match(line)) { headerLevel = 3; content = h3.matched(1); }
            else if (h2.match(line)) { headerLevel = 2; content = h2.matched(1); }
            else if (h1.match(line)) { headerLevel = 1; content = h1.matched(1); }

            content = boldItalic.map(content, (e) -> { return '<b><i>${e.matched(1)}</i></b>'; });
            content = bold.map(content, (e) -> { return '<b>${e.matched(1)}</b>'; });
            content = italic.map(content, (e) -> { return '<i>${e.matched(1)}</i>'; });
            content = strike.map(content, (e) -> { return '<s>${e.matched(1)}</s>'; });
            content = code.map(content, (e) -> { return '<font face="Courier New" color="#F6871F">${e.matched(1)}</font>'; });

            if (isList) {
                if (!inList) {
                    result.push('<ul>');
                    inList = true;
                }
                result.push('<li>${content}</li>');
            } else {
                if (inList) {
                    result.push('</ul>');
                    inList = false;
                }

                if (headerLevel > 0) {
                    var size = (headerLevel == 1) ? 32 : (headerLevel == 2) ? 28 : (headerLevel == 3) ? 24 : (headerLevel == 4) ? 20 : (headerLevel == 5) ? 17 : 14;
                    result.push('<font size="${size}">${(headerLevel < 5 ? '<b>' : '')}${content}${(headerLevel < 5 ? '</b>' : '')}</font><br>');
                } else {
                    result.push('${content}<br>');
                }
            }
        }

        if (inList) result.push('</ul>');

        return result.join('\n');
    }

    public static function truncateToFitWidth(text:String, maxWidth:Float, fontSize:Int):String {
        if (text == null || text == "") return "";

        var measurer = new TextField();
        var format = new TextFormat(null, cast fontSize * 1.2);
        measurer.defaultTextFormat = format;
        measurer.text = text;

        if (measurer.textWidth <= maxWidth)
            return text;

        var truncated = text;
        while (measurer.textWidth > maxWidth && truncated.length > 0) {
            truncated = truncated.substr(0, truncated.length - 1);
            measurer.text = truncated + "...";
        }

        return measurer.text;
    }

    public static function roundCorners(source:BitmapData, cornerRadius:Float):BitmapData {
        var shape = new Shape();
        shape.graphics.beginBitmapFill(source, new Matrix(), false, true);

        var ellipseSize = cornerRadius * 2;
        shape.graphics.drawRoundRect(0, 0, source.width, source.height, ellipseSize, ellipseSize);
        shape.graphics.endFill();

        var roundedData = new BitmapData(source.width, source.height, true, 0x00000000);
        roundedData.draw(shape);

        return roundedData;
    }

    public static function circleify(source:BitmapData):BitmapData {
        var shape = new Shape();
        shape.graphics.beginBitmapFill(source, new Matrix(), false, true);

        shape.graphics.drawCircle(source.width/2, source.height/2, source.width/2);
        shape.graphics.endFill();

        var roundedData = new BitmapData(source.width, source.height, true, 0x00000000);
        roundedData.draw(shape);

        return roundedData;
    }

    public static function formatBytes(bytes:Float):String {
        if (bytes < 1024)
            return Std.int(bytes) + ' Bytes';
        else if (bytes < 1024 * 1024)
            return Std.string(Math.round(bytes / 1024 * 100) / 100) + ' KB';
        else if (bytes < 1024 * 1024 * 1024)
            return Std.string(Math.round(bytes / (1024 * 1024) * 100) / 100) + ' MB';
        else
            return Std.string(Math.round(bytes / (1024 * 1024 * 1024) * 100) / 100) + ' GB';
    }
}