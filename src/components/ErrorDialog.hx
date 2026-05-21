package components;

import haxe.ui.containers.dialogs.Dialog;
import hlwnative.HLNativeWindow;

@:build(haxe.ui.macros.ComponentMacros.build("ui/components/errordialog.xml"))
class ErrorDialog extends Dialog {
    public function new(title:String, message:String, resetTitlebarColorOnClose:Bool = true, onClose:Void->Void = null) {
        super();
        haxe.Timer.delay(function() {
            HLNativeWindow.setWindowTitlebarColor(0x212324);
        }, 25);
        this.title = title;
        errorMessage.text = parseErrorText(message);
        buttons = DialogButton.OK;
        onDialogClosed = (_) -> {
            if (resetTitlebarColorOnClose)
                HLNativeWindow.setWindowTitlebarColor(0x3d3f41);
            if (onClose != null) {
                onClose();
            }
        }
    }

    public static function parseErrorText(text:String):String {
        var result = text;
        // %%text%% -> bold italic teal
        result = ~/%%(.+?)%%/g.replace(result, '<font color="#3AE4D8"><b><i>$1</i></b></font>');
        // @@path@@ -> codeblock
        result = ~/@@((.|\n)+?)@@/g.replace(result, '<font face="Courier New" color="#8EACAD">$1</font>');
        // ##link## -> hyperlink
        result = ~/##(.+?)##/g.replace(result, '<a href="https://github.com/blueskythlikesclouds/DivaModLoader"><font color="#4AB8C4"><u>$1</u></font></a>');
        return result;
    }
}