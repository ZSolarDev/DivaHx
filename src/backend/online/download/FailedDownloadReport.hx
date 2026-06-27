package backend.online.download;

import backend.online.gamebanana.GBModData;

typedef FailedDownloadReport = {
    var title:String;
    var data:String;
    var modType:String;
    var mod:Dynamic;
    var modData:GBModData;
}