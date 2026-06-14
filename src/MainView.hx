package;

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

    public function new() {
        super();
        var isValid = Validate.isValidMMPath();
        modManager.disabled = !isValid;
        mainTabs.pageIndex = isValid ? 0 : 1;
        regenDataSrc();
        Update.register(this, update);
    }

    public function update(dt:Float) {
        var isValid = Validate.isValidMMPath();
        modManager.disabled = !isValid;
        if (isValid) {
            if (curDs == null)
                regenDataSrc();

            @:privateAccess
            var newDs = curDs._array;
            var diff = false;
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
            if (diff)
                saveModList();
            oldDs = Copy.copy(newDs);
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

    public function regenDataSrc() {
        if (Validate.isValidMMPath()) {
            modConfig = TomlParser.parseFile(Path.join([Config.data.mmPath, 'config.toml']));
            var realModlist = FileSystem.readDirectory(Path.join([Config.data.mmPath, modConfig.mods]));
            curDs = new ArrayDataSource<Dynamic>();
            curDs.allowCallbacks = true;
            var priority:Array<String> = modConfig.priority;
            for (mod in priority) 
                curDs.add({ colEnabled: true, colName: mod });
            for (mod in realModlist)
                if (!priority.contains(mod))
                    curDs.add({ colEnabled: false, colName: mod });
            modList.dataSource = curDs;
        }
    }

    override function disposeComponent() {
        super.disposeComponent();
        Update.unregister(this);
    }
}