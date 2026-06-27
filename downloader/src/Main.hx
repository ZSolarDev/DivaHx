package;

import hxFileManager.FileManager;
import haxe.io.Path;
import hl.UI;
import sys.FileSystem;
import dma.DMAMod;
import gamebanana.GBMod;
import gamebanana.GBModData;
import sys.io.File;
import haxe.Json;
import haxe.ui.themes.Theme;
import haxe.ui.Toolkit;
import haxe.ui.HaxeUIApp;
import haxe.Exception;

using StringTools;

class Main {
    public static var isDma:Bool = true;
    public static var dmaMod:DMAMod;
    public static var gbMod:GBMod;
    public static var gbModData:GBModData;
    public static var mmModPath:String = '';

    public static function main() {
        UI.closeConsole();
        
        try {
            FileManager.init();
            if (FileSystem.exists('DMAMDATA')) {
                dmaMod = Json.parse(File.getContent('DMAMDATA'));
                FileSystem.deleteFile('DMAMDATA');
            } else {
                if (FileSystem.exists('GBMDATA')) {
                    isDma = false;
                    var data = Json.parse(File.getContent('GBMDATA'));
                    gbMod = data.mod;
                    gbModData = data.modData;
                    FileSystem.deleteFile('GBMDATA');
                } else
                    throw new Exception('Mod data was not found!');
            }
            if (FileSystem.exists('config.dhxc')) {
                var data = Json.parse(File.getContent('config.dhxc'));
                if (FileSystem.exists(data.mmPath)) {
                    if (FileSystem.exists(Path.join([data.mmPath, 'config.toml']))) {
                        var modPath = getModsPathFromToml(File.getContent(Path.join([data.mmPath, 'config.toml'])));
                        if (FileSystem.exists(Path.join([data.mmPath, modPath])))
                            mmModPath = Path.join([data.mmPath, modPath]);
                        else
                            throw new Exception('Your Project Diva Mega Mix+ mods folder specified in config.toml was not found! Is DML configured correctly?');
                    } else 
                        throw new Exception('Your Project Diva Mega Mix+ config.toml was not found! Is DML installed?');
                } else
                    throw new Exception('Your Project Diva Mega Mix+ was not found! Have you configured DivaHx?');
            } else
                throw new Exception('Your DivaHx config was not found!');
        } catch (e) {
            throwError(e);
        }

        Toolkit.theme = Theme.DARK;
        var app = new HaxeUIApp();
        app.ready(function() {
            app.addComponent(new MainView());

            app.start();
        });
    }

    static function getModsPathFromToml(tomlContent:String):String {
        var regex = ~/^\s*mods\s*=\s*"([^"]*)"\s*$/m;
        if (regex.match(tomlContent)) 
            return regex.matched(1);
        return '';
    }
}
