package;

import hl.UI;
import backend.online.download.DownloadReportManager;
import backend.utils.SingleInstance;
import boot.BootError;
import backend.utils.Validate;
import hlwnative.HLNativeWindow;
import haxe.ui.themes.Theme;
import haxe.ui.Toolkit;
import backend.utils.Config;
import haxe.ui.HaxeUIApp;
import hxFileManager.FileManager;

class Main {
    public static var app:HaxeUIApp;
    
    public static function main() {
        #if (!debug)
        UI.closeConsole();
        #end
        if (!SingleInstance.check()) {
            // Another instance is running
            Toolkit.theme = Theme.DARK;
            app = new HaxeUIApp();
            app.ready(function() {
                app.addComponent(new BootError());

                app.start();
            });
            return;
        }

        init();
    }

    private static function init() {
        FileManager.init();
        HLNativeWindow.setWindowTitlebarColor(0x2c2f30);
        Config.bind();
        Validate.invalidateMMPath();
        Validate.checkInstallation(Config.data.mmPath);
        Toolkit.theme = Theme.DARK;

        app = new HaxeUIApp();
        app.ready(function() {
            DownloadReportManager.init();
            app.addComponent(new MainView());

            app.start();
        });
    }
}
