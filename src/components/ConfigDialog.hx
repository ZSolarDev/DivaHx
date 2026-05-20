package components;

import haxe.ui.components.Button;
import openfl.display.Bitmap;
import openfl.display.DisplayObjectContainer;
import backend.utils.Config;
import hlwnative.HLNativeWindow;
import openfl.events.Event;
import openfl.filesystem.File;
import haxe.ui.containers.dialogs.OpenFileDialog;
import lime.ui.FileDialog;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.Dialog;

using StringTools;

@:build(haxe.ui.macros.ComponentMacros.build("ui/components/configdialog.xml"))
class ConfigDialog extends Dialog {
    public function new() {
        super();
        haxe.Timer.delay(function() {
            HLNativeWindow.setWindowTitlebarColor(0x212324);
        }, 25);
        buttons = DialogButton.CANCEL | DialogButton.APPLY;
        mmpath.text = Config.data.mmPath;
        setmmpath.onClick = (e) -> {
            var path = HLNativeWindow.pickDirectory('MM+ Directory');

            if (path != null)
                mmpath.text = path;
        }
        onDialogClosed = (e) -> {
            HLNativeWindow.setWindowTitlebarColor(0x3d3f41);
            if (e.button == DialogButton.APPLY) {
                Config.data.mmPath = mmpath.text;
                Config.flush();
            }
        }
    }
}