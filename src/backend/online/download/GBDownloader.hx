package backend.online.download;

import backend.online.gamebanana.GBMod;
import backend.online.gamebanana.GBModData;
import haxe.Json;
import sys.io.File;

class GBDownloader {
    public static function downloadMod(mod:GBMod, modData:GBModData) {
        File.saveContent('GBMDATA', Json.stringify({
            mod: mod,
            modData: modData
        }));
        Sys.command('cmd.exe /c start "" ./hlruntime.exe ./DivaDownloader.hl > crash_log.txt 2>&1');
    }
}