package;

import backend.utils.Update;
import backend.utils.Validate;
import components.DraggableTableView;
import haxe.ui.core.ComponentClassMap;
import hlwnative.HLNativeWindow;
import haxe.ui.themes.Theme;
import haxe.ui.Toolkit;
import backend.utils.Config;
import haxe.ui.HaxeUIApp;

class Main {
    public static function main() {
        HLNativeWindow.setWindowTitlebarColor(0x2c2f30);
        Config.bind();
        Validate.invalidateMMPath();
        Validate.checkInstallation(Config.data.mmPath);
        Toolkit.theme = Theme.DARK;
        var app = new HaxeUIApp();
        app.ready(function() {
            app.addComponent(new MainView());

            app.start();
        });
    }
}
