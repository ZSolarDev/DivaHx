package backend.online.dma;

import haxe.Json;
import haxe.Http;
using StringTools;

class DMA {
    public static function getMods(query:String, sort:DMASortType, types:Array<DMAPostType>, offset:Int, limit:Int):DMAModListResult {
        var res:DMAModListResult = {
            mods: [],
            error: ''
        }
        var url = buildURL(query, sort, types, offset, limit);
        var http = new Http(url);

        http.onData = (jsonText:String) -> {
            try {
                var parsedMods:Array<DMAMod> = Json.parse(jsonText);
                res.mods = parsedMods;
            } catch (e) {
                http.onError('Failed to parse mods!\nERROR:\n${e.message}\nSTACK:\n${e.stack.toString()}');
            }
        }
        http.onError = (error:String) -> {
            res.error = error;
        }

        http.request(false);
        return res;
    }

    static function buildURL(query:String, sort:DMASortType, types:Array<DMAPostType>, offset:Int, limit:Int):String {
        var url = 'https://divamodarchive.com/api/v1/posts';
        // Search query
        if (query != '')
            url += '?query=$query';

        // Sort
        url += '&sort=$sort';

        // The filter is meilisearch boolean logic syntax
        var typesStr = '';
        for (type in types) {
            if (typesStr == '') {
                url += '&filter=';
                typesStr += '(post_type = "$type"';
            } else
                typesStr += ' OR post_type = "$type"';
        }
        if (typesStr != '')
            typesStr += ')';
        url += typesStr.urlEncode();

        // Offset
        url += '&offset=$offset';

        // Limit
        url += '&limit=$limit';

        trace('DMA URL: ' + url);
        return url;
    }
}