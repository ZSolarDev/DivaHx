package;

import sys.io.Process;
import backend.utils.Update;
import haxe.runtime.Copy;
import sys.FileSystem;
import haxe.io.Path;
import sys.io.File;
import haxe.ui.data.ArrayDataSource;
import openfl.events.Event;
import backend.utils.Validate;
import backend.utils.Config;
import haxe.ui.containers.VBox;
import backend.utils.TomlParser;
import openfl.Lib;

using StringTools;

@:build(haxe.ui.ComponentBuilder.build("ui/main-view.xml"))
class MainView extends VBox {
    public var modConfig:Dynamic = '';
    public var oldDs:Array<Dynamic> = [];
    public var curDs:ArrayDataSource<Dynamic> = null;
    public var oldEnabled:Bool = false;
    public var oldConsole:Bool = false;

    public function new() {
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
        Update.register(this, update);
    }

    public function update(dt:Float) {
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
                finalModList.push(mod.colName);
                processedModList.push('"${mod.colName}"');
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
        for (item in FileSystem.readDirectory(path)) {
            var full = Path.join([path, item]);
            total += FileSystem.isDirectory(full) ? getFolderSize(full) : FileSystem.stat(full).size;
        }
        return total;
    }

    function formatBytes(bytes:Float):String {
        if (bytes < 1024)
            return Std.int(bytes) + ' Bytes';
        else if (bytes < 1024 * 1024)
            return Std.string(Math.round(bytes / 1024 * 100) / 100) + ' KB';
        else if (bytes < 1024 * 1024 * 1024)
            return Std.string(Math.round(bytes / (1024 * 1024) * 100) / 100) + ' MB';
        else
            return Std.string(Math.round(bytes / (1024 * 1024 * 1024) * 100) / 100) + ' GB';
    }

    public function regenDataSrc() {
        if (Validate.isValidMMPath()) {
            modConfig = TomlParser.parseFile(Path.join([Config.data.mmPath, 'config.toml']));
            oldEnabled = modConfig.enabled;
            oldConsole = modConfig.console;
            var realModlist = FileSystem.readDirectory(Path.join([Config.data.mmPath, modConfig.mods]));
            curDs = new ArrayDataSource<Dynamic>();
            curDs.allowCallbacks = true;
            var priority:Array<String> = modConfig.priority;
            for (mod in priority) 
                curDs.add({ colEnabled: true, colName: mod, colSize: formatBytes(getFolderSize(Path.join([Config.data.mmPath, modConfig.mods, mod]))) });
            for (mod in realModlist)
                if (!priority.contains(mod))
                    curDs.add({ colEnabled: false, colName: mod, colSize: formatBytes(getFolderSize(Path.join([Config.data.mmPath, modConfig.mods, mod]))) });
            @:privateAccess
            oldDs = Copy.copy(curDs._array);
            modList.dataSource = curDs;
        }
    }

    override function disposeComponent() {
        super.disposeComponent();
        Update.unregister(this);
    }
}