package backend.online.gamebanana;

import haxe.Json;
import haxe.Http;

using StringTools;

class GB {
    public static function getModData(mod:GBMod):GBModDataResult {
        var res:GBModDataResult = {
            modData: null,
            error: ''
        }

        var http = new Http('https://api.gamebanana.com/Core/Item/Data?itemtype=Mod&itemid=${mod._idRow}&fields=text,downloads,Files().aFiles(),likes,Nsfw().bIsNsfw(),description');
        var jsonText = '';

        http.onData = (response:String) -> {
            jsonText = response;
        }
        
        http.onError = (error:String) -> {
            res.error = error;
        }

        http.request(false);

        if (res.error != '')
            return res;

        try {
            var parsedModData:GBModData = Json.parse(jsonText);
            res.modData = parsedModData;
        } catch (e) { // If the request failed, it's probably a GBModDataError..
            try {
                var error = Json.parse(jsonText);
                if (error.error != null && error.errorCode != null)
                    res.error = 'Failed to parse mod data(ModID: ${mod._idRow})!\nERROR: ${error.error}\nCODE: ${error.errorCode}';
                else // uh oh
                    res.error = 'Failed to parse mod data(ModID: ${mod._idRow})!\nERROR: ${e.message}\nSTACK:${e.stack.toString()}';
            } catch (e2) {
                res.error = 'Failed to parse mod data(ModID: ${mod._idRow})!\nERROR: ${e.message}\nSTACK:${e.stack.toString()}\n\n----------------------------------------------\n\nERROR PARSING ERROR: ${e2.message}\nSTACK:${e2.stack.toString()}';
            }
        }

        return res;
    }
    public static function getMods(query:String, category:GBCategory, sort:GBSortType, page:Int, modsPerPage:Int):GBModListResult {
        var res:GBModListResult = {
            mods: [],
            error: ''
        }

        // All of this extra code because I can't filter by category when searching for a query btw.
        var hasCategory = false;
        var targetCategoryName = '';

        if (category != null) {
            var catStr:String = Std.string(category).trim();
            if (catStr != '' && catStr != 'None' && catStr != 'null') {
                hasCategory = true;
                if (catStr.indexOf(':') != -1) {
                    targetCategoryName = catStr.split(':')[1];
                } else {
                    targetCategoryName = catStr;
                }
            }
        }

        var finalMods:Array<GBMod> = [];
        var apiPageToFetch = 1; 
        var reachedEnd = false;

        var targetSkipCount = (page - 1) * modsPerPage;
        var validModsSkippedSoFar = 0;
        var reachedTargetUiPageStart = (targetSkipCount == 0);

        while (finalMods.length < modsPerPage && !reachedEnd) {
            var url = buildURL(query, category, sort, apiPageToFetch, modsPerPage);

            var http = new Http(url);
            var jsonText:String = ''; 

            http.onData = (response:String) -> {
                jsonText = response;
            }

            http.onError = (error:String) -> {
                res.error = error;
            }

            http.request(false);

            if (res.error != '')
                return res;

            if (jsonText == '')
                break;

            try {
                var response:Dynamic = Json.parse(jsonText);
                var parsedMods:Array<Dynamic> = (response._aRecords != null) ? cast response._aRecords : [];
            
                var index = 0;
                while (index < parsedMods.length) {
                    var mod:Dynamic = parsedMods[index];
                    index++; 
                
                    var modName:String = (mod._sName != null) ? (cast mod._sName).toLowerCase() : '';
                    var categoryMatches = !hasCategory || (mod._aRootCategory != null && mod._aRootCategory._sName == targetCategoryName);
                    var nameMatches = (query == '') || modName.toLowerCase().contains(query.toLowerCase());
                
                    if (categoryMatches && nameMatches) {
                        if (!reachedTargetUiPageStart) {
                            validModsSkippedSoFar++;
                            if (validModsSkippedSoFar >= targetSkipCount)
                                reachedTargetUiPageStart = true;
                            continue; 
                        }
                        finalMods.push(cast mod);
                    }
                
                    if (finalMods.length == modsPerPage)
                        break;
                }
            } catch (e) { // If the request failed, the result is probably a GBError. Let's try to parse it as such
                var error:GBError = Json.parse(jsonText);
                if (error._sErrorCode != null && error._sErrorData != null)
                    http.onError('Failed to parse mods!\nERROR: ${error._sErrorCode}\nDATA:\n${error._sErrorData}');
                else // Yeah so if it's not a GBError, something is really wrong..
                    http.onError('Failed to parse mods!\nERROR: ${e.message}\nSTACK:${e.stack.toString()}');
                
            }

            if (finalMods.length >= modsPerPage) 
                break;

            apiPageToFetch++;
        }
        
        res.mods = finalMods;
        return res;
    }

    static function buildURL(query:String, category:GBCategory, sort:GBSortType, page:Int, modsPerPage:Int):String {
        var url = 'https://gamebanana.com/apiv12/' + ((query != '' && query != null) ? 'Util/Search/Results' : 'Mod/Index');

        // Search query
        if (query != '' && query != null) {
            url += '?_sSearchString=${query.urlEncode()}';
            url += '&_sModelName=Mod';
        }

        // Page
        url += '${((query != '' && query != null) ? '&' : '?')}_nPage=$page';

        // Mods per page
        url += '&_nPerPage=$modsPerPage';

        // Sort (NOTE: The sort does NOT WORK when a query is present! I don't know why..)
        url += '&_sSort=$sort';

        // Category
        if (query != '' && query != null)
            url += ((category != None) ? '&_idCategoryRow=${(category:String).split(':')[0]}' : '&_idGameRow=16522');
        else
            url += ((category != None) ? '&_aFilters[Generic_Category]=${(category:String).split(':')[0]}' : '&_aFilters[Generic_Game]=16522');

        return url;
    }
}