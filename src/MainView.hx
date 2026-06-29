package;

import sys.thread.Thread;
import haxe.ui.Toolkit;
import hxFileManager.HttpManager;
import components.dialogs.ScrollDialog;
import haxe.ui.notifications.NotificationType;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.containers.menus.MenuSeparator;
import components.dialogs.TextEditDialog;
import haxe.ui.events.ItemEvent;
import haxe.ui.core.Screen;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.Menu;
import haxe.ui.components.Button;
import haxe.ui.events.UIEvent;
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
import backend.utils.ModTomlProcessor;
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
        modList.onComponentEvent = (e:UIEvent) -> {
            var source = Reflect.field(e, 'source');
            if (e.type == ItemEvent.COMPONENT_EVENT && (source is Button) && cast(source, Button).id == 'colActions') {
                //var button:Button = cast source;
                var rowData = e.data;

                var menu = new Menu();

                var menuItems:Array<MenuItemData> = [
                    {
                        text: 'Delete Mod',
                        disabledText: 'Mod not found...',
                        condition: () -> {
                            return FileSystem.exists(Path.join([Config.data.mmPath, modConfig.mods, modNameToMod.get(rowData.colName)]));
                        },
                        onClick: () -> {
                            var modName = modNameToMod.get(rowData.colName);
                            var modPath = Path.join([Config.data.mmPath, modConfig.mods, modName]);
                            FileManager.deletePathAsync(modPath, () -> {
                                NotificationManager.instance.addNotification({
                                    title: 'Mod Deleted',
                                    body: 'Mod "${rowData.colName}" has been deleted.',
                                    expiryMs: -1,
                                    type: NotificationType.Success
                                });
                                regenDataSrc();
                            }, (error) -> {
                                if (error.contains('SysError')) {
                                    FileManager.deleteElevated(modPath, () -> {
                                        NotificationManager.instance.addNotification({
                                            title: 'Mod Deleted',
                                            body: 'Mod "${rowData.colName}" has been deleted (with admin rights).',
                                            expiryMs: -1,
                                            type: NotificationType.Success
                                        });
                                        regenDataSrc();
                                    }, (elevatedError) -> {
                                        NotificationManager.instance.addNotification({
                                            title: 'Mod Deletion Failed',
                                            body: 'Mod "${rowData.colName}" failed to delete even with admin rights. Error: $elevatedError',
                                            expiryMs: -1,
                                            type: NotificationType.Error
                                        });
                                    });
                                } else {
                                    NotificationManager.instance.addNotification({
                                        title: 'Mod Deleted',
                                        body: 'Mod "${rowData.colName}" failed to delete. Error: $error',
                                        expiryMs: -1,
                                        type: NotificationType.Error
                                    });
                                }
                            });
                        },
                        isSeparator: false
                    },
                    {
                        text: 'Open Mod Folder',
                        disabledText: 'Mod Folder not found...',
                        condition: () -> {
                            return FileSystem.exists(Path.join([Config.data.mmPath, modConfig.mods, modNameToMod.get(rowData.colName)]));
                        },
                        onClick: () -> {
                            var folderPath = Path.join([Config.data.mmPath, modConfig.mods, modNameToMod.get(rowData.colName)]);
                            folderPath = folderPath.split('/').join('\\');
                            Sys.command('explorer.exe', [folderPath]);
                        },
                        isSeparator: false
                    },
                    {
                        text: '',
                        disabledText: '',
                        condition: null,
                        onClick: null,
                        isSeparator: true
                    },
                    {
                        text: 'Mod Info',
                        disabledText: 'Mod config.toml not found...',
                        condition: () -> {
                            return getModToml(modNameToMod.get(rowData.colName)) != '';
                        },
                        onClick: () -> {
                            var modInfo = ModTomlProcessor.buildModInfoString(getModToml(modNameToMod.get(rowData.colName)));
                            var dialog = new ScrollDialog('Mod Info for "${rowData.colName}"', modInfo, true);
                            dialog.showDialog();
                        },
                        isSeparator: false
                    },
                    {
                        text: 'Configure Mod',
                        disabledText: 'Mod cannot be configured...',
                        condition: () -> {
                            return getModToml(modNameToMod.get(rowData.colName)) != '' && ModTomlProcessor.hasNonCommentLine(ModTomlProcessor.stripMetadataLines(getModToml(modNameToMod.get(rowData.colName))).res);
                        },
                        onClick: () -> {
                            var modToml = getModToml(modNameToMod.get(rowData.colName));
                            var res = ModTomlProcessor.stripMetadataLines(modToml);
                            var metadata = res.metadata;
                            var dialog = new TextEditDialog('Edit config for "${rowData.colName}"', res.res, true, (newData:String) -> {
                                var finalToml = '${metadata.join('\n')}\n$newData';
                                File.saveContent(Path.join([Config.data.mmPath, modConfig.mods, modNameToMod.get(rowData.colName), 'config.toml']), finalToml);
                            });
                            dialog.showDialog();
                        },
                        isSeparator: false
                    },
                ];
                for (menuItemData in menuItems) {
                    if (menuItemData.isSeparator) {
                        var separator = new MenuSeparator();
                        separator.percentWidth = 100;
                        menu.addComponent(separator);
                    } else {
                        var menuItem = new MenuItem();
                        if (menuItemData.condition()) {
                            menuItem.text = menuItemData.text;
                            menuItem.onClick = (_) -> menuItemData.onClick();
                        } else {
                            menuItem.text = menuItemData.disabledText;
                            menuItem.disabled = true;
                        }
                        menu.addComponent(menuItem);
                    }
                }

                Screen.instance.addComponent(menu);
                var thresholdY = Screen.instance.height * 0.85;
                if (Screen.instance.currentMouseY < thresholdY)
                    menu.top = Screen.instance.currentMouseY + 1;
                else
                    menu.top = Screen.instance.currentMouseY - menu.height - 1;
                menu.left = Screen.instance.currentMouseX + 1;
            }
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

        var ds:ArrayDataSource<Dynamic> = cast modList.dataSource;
        var rawArray = @:privateAccess ds._array;

        for (mod in rawArray) {
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
            modList.resetFilter();
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
                curDs.add({ colEnabled: true, colName: getModName(mod), colSize: Misc.formatBytes(getFolderSize(Path.join([Config.data.mmPath, modConfig.mods, mod]))), colActions: 'Actions...' });
            for (mod in realModList) {
                modNameToMod.set(getModName(mod), mod);
                if (!priority.contains(mod))
                    curDs.add({ colEnabled: (oldAllMods.length > 0 && !oldAllMods.contains(getModName(mod))), colName: getModName(mod), colSize: Misc.formatBytes(getFolderSize(Path.join([Config.data.mmPath, modConfig.mods, mod]))), colActions: 'Actions...' });
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

    function getModToml(dirtyModName:String):String {
        var path = Path.join([Config.data.mmPath, modConfig.mods, dirtyModName, 'config.toml']);
        if (FileSystem.exists(path))
            return File.getContent(path);
        return '';
    }

    function getModName(dirtyModName:String):String {
        var modToml = getModToml(dirtyModName);
        if (modToml != '') {
            var name = ModTomlProcessor.getModStringFromToml(modToml, 'name');
            if (name != '')
                return name;
        }
        return dirtyModName;
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

typedef MenuItemData = {
    var text:String;
    var disabledText:String;
    var condition:Void->Bool;
    var onClick:Void->Void;
    var isSeparator:Bool;
}