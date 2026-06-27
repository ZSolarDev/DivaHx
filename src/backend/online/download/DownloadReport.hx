package backend.online.download;

import backend.online.gamebanana.GBModData;

typedef DownloadReport = {
    var ?mod:Dynamic;
    var ?modType:String;
    var ?modData:GBModData;
    var ?fileIdx:Int;
    var ?archiveFolder:String;
    var ?extractionLog:String;
}