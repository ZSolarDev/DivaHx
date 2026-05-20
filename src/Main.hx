package;

import hlwnative.HLNativeWindow;
import haxe.ui.themes.Theme;
import haxe.ui.Toolkit;
import backend.utils.Config;
import haxe.ui.HaxeUIApp;

class Main {
    public static function main() {
        HLNativeWindow.setWindowTitlebarColor(0x3d3f41);
        Config.bind();
        Toolkit.theme = Theme.DARK;
        var app = new HaxeUIApp();
        app.ready(function() {
            app.addComponent(new MainView());

            app.start();
        });
    }
}
