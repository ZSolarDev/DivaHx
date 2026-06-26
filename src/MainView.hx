package;

import backend.online.dma.DMAMod;
import components.dialogs.ScrollDialog;
import components.dialogs.DMAModDownloadDialog;
import backend.online.download.DownloadReport;
import haxe.Json;
import haxe.ui.containers.dialogs.Dialogs;
import backend.utils.Misc;
import openfl.Lib;
import lime.app.Application;
import haxe.ui.events.UIEvent;
import haxe.ui.core.Screen;
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
    public var trackingMReport:Bool = false;
    public var modsWatcher:Int = -1;
    public static var modNameToMod:Map<String, String> = new Map<String, String>();
    public static var allMods:Array<String> = [];
    public static var enabledMods:Array<String> = [];

    public function new() {
        Lib.application.window.setMinSize(1280, 720);
        Lib.application.window.resizable = false;
        super();
        var isValid = Validate.isValidMMPath();
        modManager.disabled = !isValid;
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
        if (FileSystem.exists('MREPORT') && !trackingMReport) {
            trackingMReport = true;
            try {
                var data:DownloadReport = Json.parse(File.getContent('MREPORT'));
                var dialog:ScrollDialog = null;
                if (data.type == 'error') {
                    if (data.modType == 'dma' || data.modType == '')
                        dialog = new DMAModDownloadDialog(data.title, '### ${data.title}\n${data.data}', true, ((data.mod == null) ? null : (data.mod:DMAMod)));
                } else {
                    if (data.modType == 'dma')
                        dialog = new DMAModDownloadDialog(data.title, '#### ${data.data}', false, (data.mod:DMAMod));
                }
                if (dialog != null) {
                    trace('Mod Download Report: ${data.title}');
                    dialog.showDialog();
                }
                FileSystem.deleteFile('MREPORT');

                trackingMReport = false;
            } catch (e) {
                var dialog:ScrollDialog = new ScrollDialog('Failed to display a Mod Download Report!', '### Failed to display a Mod Download Report!\nError: ${e.message}\nStack:${e.stack.toString()}', true);
                dialog.showDialog();

                FileSystem.deleteFile('MREPORT');
                trackingMReport = false;
            }
        }
        var isValid = Validate.isValidMMPath();
        modManager.disabled = !isValid;
        if (isValid) {
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
        }
    }

    public function saveModList() {
        var finalModList = [];
        var processedModList = [];
        for (modIdx in 0...modList.dataSource.size) {
            var mod = modList.dataSource.get(modIdx);
            if (mod.colEnabled) {
                finalModList.push(modNameToMod.get(mod.colName) != null ? modNameToMod.get(mod.colName) : mod.colName);
                processedModList.push('"${(modNameToMod.get(mod.colName) != null ? modNameToMod.get(mod.colName) : mod.colName)}"');
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
                    if (priority.contains(name))
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
        var name = getModNameFromToml(File.getContent(Path.join([Config.data.mmPath, modConfig.mods, mod, 'config.toml'])));
        if (name != '')
            return name;
        return mod;
    }
    
    function getModNameFromToml(tomlContent:String):String {
        var regex = ~/^\s*name\s*=\s*"([^"]*)"\s*$/m;
        if (regex.match(tomlContent)) 
            return regex.matched(1);
        return '';
    }

    override function disposeComponent() {
        super.disposeComponent();
        if (modsWatcher != -1)
            FileManager.stopWatcher(modsWatcher);
        Update.unregister(this);
    }
}