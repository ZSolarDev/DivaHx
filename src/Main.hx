package;

import backend.utils.SingleInstance;
import sys.net.Address;
import boot.BootError;
import sys.io.FileOutput;
import sys.FileSystem;
import lime.app.Application;
import sys.io.File;
import openfl.Lib;
import backend.utils.Validate;
import hlwnative.HLNativeWindow;
import haxe.ui.themes.Theme;
import haxe.ui.Toolkit;
import backend.utils.Config;
import haxe.ui.HaxeUIApp;
import sys.net.Socket;
import sys.net.Host;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;
import lime.app.Application;
import hxFileManager.FileManager;

class Main {
    public static var app:HaxeUIApp;
    
    public static function main() {
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
            app.addComponent(new MainView());

            app.start();
        });
    }
}
