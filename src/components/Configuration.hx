package components;

import sys.FileSystem;
import sys.io.File;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.VBox;
import backend.utils.Validate;
import haxe.ui.components.Button;
import backend.utils.Config;
import hlwnative.HLNativeWindow;

using StringTools;

@:build(haxe.ui.macros.ComponentMacros.build("ui/components/configuration.xml"))
class Configuration extends VBox {
    public function new() {
        super();
        mmpath.text = Config.data.mmPath;
        setmmpath.onClick = (e) -> {
            var path = HLNativeWindow.pickDirectory('MM+ Directory');
            if (path != null) {
                // Because for some reason, the string is kinda valid but under the hood it's not.
                // It lets you do string things with the string, but it'll break in some situations,
                // like when trying to use some methods from the Path class on it, you'll get an error.
                // I decided to just save the path to a file and read it off so I get back a fully valid string.
                File.saveContent('dummy.txt', path);
                mmpath.text = File.getContent('dummy.txt');
                FileSystem.deleteFile('dummy.txt');
            }
        }
        applyButton.onClick = (_) -> {
            var path = mmpath.text;
            var valid = Validate.validateInstallation(path);
            if (!valid.isValid && path.length > 0) {
                var err = new ErrorDialog('Invalid MM+ Installation', valid.details, true, () -> {
                    mmpath.text = Config.data.mmPath;
                });
                err.showDialog();
            } else {
                Config.data.mmPath = path;
                Config.flush();
            }
        }
        resetButton.onClick = (_) -> {
            haxe.Timer.delay(function() {
                HLNativeWindow.setWindowTitlebarColor(0x1d1f20);
            }, 25);
            Dialogs.messageBox('Are you sure you want to reset your configuration?', 'Reset Configuration', 'yesno', true, (button) -> {
                if (button == DialogButton.YES) {
                    Config.data.mmPath = '';
                    Config.flush();
                    mmpath.text = '';
                    Validate.invalidateMMPath();
                }
                HLNativeWindow.setWindowTitlebarColor(0x2c2f30);
            });
        }
    }
}