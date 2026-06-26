package;

import sys.FileSystem;
import hxFileManager.HttpManager;
import haxe.Json;
import sys.io.File;
import haxe.Exception;

class Report {
    public static function throwError(e:Exception, ?details:String) {
        if (HttpManager.output != null) {
            HttpManager.output.close();
            if (HttpManager.output.path != '' && HttpManager.output.path != null && FileSystem.exists(HttpManager.output.path))
                FileSystem.deleteFile(HttpManager.output.path);
        }
        var report:Dynamic = null;
        if ((dmaMod == null && isDma) || (gbMod == null && !isDma)) {
            report = {
                title: 'Processing of mod data failed!',
                data: (details != null ? '$details\n' : '') + 'Error: ${e.message}\nStack: ${e.stack.toString()}',
                type: 'error',
                modType: '',
                mod: null
            };
        } else {
            if (isDma)
                dmaMod.text = "";
            report = {
                title: 'Failed to download mod "${((isDma ? dmaMod.name : gbMod._sName))}"!',
                data: (details != null ? '$details\n' : '') + 'Error: ${e.message}\nStack: ${e.stack.toString()}',
                type: 'error',
                modType: (isDma ? 'dma' : 'gb'),
                mod: ((isDma ? dmaMod : gbMod):Dynamic)
            };
        }
        
        File.saveContent('MREPORT', Json.stringify(report));
        Sys.exit(1);
    }

    public static function success() {
        var report = {
            title: 'The mod "${((isDma ? dmaMod.name : gbMod._sName))}" was downloaded successfully!',
            data: 'The mod "${((isDma ? dmaMod.name : gbMod._sName))}" was installed inside of your Mega Mix+ mod folder.',
            type: 'success',
            modType: (isDma ? 'dma' : 'gb'),
            mod: ((isDma ? dmaMod : gbMod):Dynamic)
        };
        File.saveContent('MREPORT', Json.stringify(report));
        Sys.exit(0);
    }
}