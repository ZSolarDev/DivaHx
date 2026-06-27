package;

import backend.online.download.DownloadReportManager;
import backend.utils.Misc;
import openfl.Lib;
import lime.app.Application;
import backend.utils.Update;
import haxe.runtime.Copy;
import sys.FileSystem;
import haxe.io.Path;
import sys.io.File;
import haxe.ui.data.ArrayDataSource;
import backend.utils.Validate;
import backend.utils.Config;
import haxe.ui.containers.VBox;
import haxetoml.TomlParser;
import hxFileManager.FileManager;

using StringTools;

@:build(haxe.ui.ComponentBuilder.build("ui/main-view.xml"))
class MainView extends VBox {
    public var modConfig:Dynamic = '';
    public var oldDs:Array<Dynamic> = [];
    public var curDs:ArrayDataSource<Dynamic> = null;
    public var oldEnabled:Bool = false;
    public var oldConsole:Bool = false;
    public var modsWatcher:Int = -1;
    public var beganInvalid:Bool = false;
    public var alreadyHeld:Bool = false;
    public static var modNameToMod:Map<String, String> = new Map<String, String>();
    public static var allMods:Array<String> = [];
    public static var enabledMods:Array<String> = [];
    public static var instance:MainView;

    public function new() {
        instance = this;
        Lib.application.window.setMinSize(1280, 720);
        Lib.application.window.resizable = false;
        super();
        var isValid = Validate.isValidMMPath();
        modManagerTab.disabled = !isValid;
        modBrowserTab.disabled = !isValid;
        if (!isValid)
            beganInvalid = true;
        mainTabs.pageIndex = isValid ? 0 : 1;
        regenDataSrc();
        playSteam.onClick = (_) -> {
            Sys.command('cmd /c start "" "steam://rungameid/1761390"');
        }
        playExe.onClick = (_) -> {
            Sys.command('cmd /c start "" "${Path.join([Config.data.mmPath, 'DivaMegaMix.exe'])}"');
        }
        githubButton.onClick = (_) -> {
            Sys.command('cmd /c start "" "https://github.com/ZSolarDev/DivaHX"');
        }
        metadataText.htmlText = 'DivaHx V${Application.current.meta.get('version')}&#10;<font color="#888888" size="14">Created by ZSolarDev with Haxe</font>';
        Update.register(this, update);
        modsWatcher = FileManager.watchFolder(Path.join([Config.data.mmPath, modConfig.mods]), regenDataSrc);
    }
    

    public function update(dt:Float) {
        var isValid = Validate.isValidMMPath();
        modManagerTab.disabled = !isValid;
        modBrowserTab.disabled = !isValid;
        if (isValid) {
            if (mainTabs.pageIndex < 2)
                modBrowser.hidden = true;
            if (mainTabs.pageIndex == 2 && modBrowser.hidden)
                modBrowser.hidden = false;

            if (curDs == null || modConfig == null)
                regenDataSrc();

            modConfig.enabled = modsEnabled.selected;
            modList.disabled = !modConfig.enabled;
            modConfig.console = console.selected;

            @:privateAccess
            var newDs = curDs._array;
            var diff = false;
            if (modConfig.enabled != oldEnabled || modConfig.console != oldConsole)
                diff = true;
            else {
                for (modIdx in 0...newDs.length) {
                    var newMod = newDs[modIdx];
                    var oldMod = oldDs[modIdx];
                    if (oldMod == null || newMod == null)
                        continue;
                    if (newMod.colName != oldMod.colName || newMod.colEnabled != oldMod.colEnabled) {
                        diff = true;
                        break;
                    }
                }
            }
            if (diff)
                saveModList();
            oldDs = Copy.copy(newDs);
            oldEnabled = modConfig.enabled;
            oldConsole = modConfig.console;
        } else {
            mainTabs.pageIndex = 1;
        }
    }

    public function saveModList() {
        var finalModList = [];
        var processedModList = [];
        enabledMods = [];
        
        for (modIdx in 0...modList.dataSource.size) {
            var mod = modList.dataSource.get(modIdx);
            if (mod.colEnabled) {
                finalModList.push(modNameToMod.get(mod.colName) != null ? modNameToMod.get(mod.colName) : mod.colName);
                processedModList.push('"${(modNameToMod.get(mod.colName) != null ? modNameToMod.get(mod.colName) : mod.colName)}"');
                enabledMods.push(mod.colName);
            }
        }
        modConfig.priority = finalModList;
        
        var configToml:StringBuf = new StringBuf();
        configToml.add('enabled = ${modConfig.enabled}\n');
        configToml.add('console = ${modConfig.console}\n');
        configToml.add('mods = "${modConfig.mods}"\n');
        configToml.add('priority = [${processedModList.join(', ')}]\n');
        File.saveContent(Path.join([Config.data.mmPath, 'config.toml']), configToml.toString());
    }

    function getFolderSize(path:String):Float {
        var total:Float = 0;
        try {
            for (item in FileSystem.readDirectory(path)) {
                var full = Path.join([path, item]);
                total += FileSystem.isDirectory(full) ? getFolderSize(full) : FileSystem.stat(full).size;
            }
        } catch (e) {
            haxe.Timer.delay(() -> {
                try {
                    for (item in FileSystem.readDirectory(path)) {
                        var full = Path.join([path, item]);
                        total += FileSystem.isDirectory(full) ? getFolderSize(full) : FileSystem.stat(full).size;
                    }
                } catch (e) {}
            }, 1000);
        }
        return total;
    }

    public function regenDataSrc() {
        if (Validate.isValidMMPath()) {
            var oldAllMods:Array<String> = (allMods != null) ? Copy.copy(allMods) : [];
            allMods = [];
            enabledMods = [];
            modConfig = TomlParser.parseFile(Path.join([Config.data.mmPath, 'config.toml']));
            oldEnabled = modConfig.enabled;
            oldConsole = modConfig.console;
            var realModList = FileSystem.readDirectory(Path.join([Config.data.mmPath, modConfig.mods]));
            curDs = new ArrayDataSource<Dynamic>();
            curDs.allowCallbacks = true;
            var priority:Array<String> = modConfig.priority;
            for (mod in priority)
                curDs.add({ colEnabled: true, colName: getModName(mod), colSize: Misc.formatBytes(getFolderSize(Path.join([Config.data.mmPath, modConfig.mods, mod]))) });
            for (mod in realModList) {
                modNameToMod.set(getModName(mod), mod);
                if (!priority.contains(mod))
                    curDs.add({ colEnabled: (oldAllMods.length > 0 && !oldAllMods.contains(getModName(mod))), colName: getModName(mod), colSize: Misc.formatBytes(getFolderSize(Path.join([Config.data.mmPath, modConfig.mods, mod]))) });
                var name = getModName(mod);
                if (name != '') {
                    if (priority.contains(mod))
                        enabledMods.push(name);
                    allMods.push(name);
                }
            }
            @:privateAccess
            oldDs = Copy.copy(curDs._array);
            modList.dataSource = curDs;
        }
    }

    function getModName(mod:String):String {
        var path = Path.join([Config.data.mmPath, modConfig.mods, mod, 'config.toml']);
        if (FileSystem.exists(path)) {
            var name = getModNameFromToml(File.getContent(path));
            if (name != '')
                return name;
        }
        return mod;
    }
    
    function getModNameFromToml(tomlContent:String):String {
        var regex = ~/^\s*name\s*=\s*"([^"]*)"\s*$/m;
        if (regex.match(tomlContent)) 
            return regex.matched(1);
        return '';
    }

    public static function isModInstalled(searchName:String):Bool {
        var cleanSearch = searchName.toLowerCase().trim();
        for (modName in allMods) {
            if (modName.toLowerCase().trim() == cleanSearch) return true;
        }
        return false;
    }

    public static function isModEnabled(searchName:String):Bool {
        var cleanSearch = searchName.toLowerCase().trim();
        for (modName in enabledMods) {
            if (modName.toLowerCase().trim() == cleanSearch) return true;
        }
        return false;
    }

    override function disposeComponent() {
        super.disposeComponent();
        if (modsWatcher != -1)
            FileManager.stopWatcher(modsWatcher);
        Update.unregister(this);
        DownloadReportManager.dispose();
    }
}