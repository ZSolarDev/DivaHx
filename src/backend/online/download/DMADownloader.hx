package backend.online.download;

import backend.online.dma.DMAMod;
import haxe.Json;
import sys.io.File;

class DMADownloader {
    public static function downloadMod(mod:DMAMod) {
        File.saveContent('DMAMDATA', Json.stringify(mod));
        Sys.command('cmd.exe /c start "" ./hlruntime.exe ./DivaDownloader.hl > crash_log.txt 2>&1');
    }
}