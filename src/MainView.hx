package ;

import haxe.ui.components.Button;
import haxe.ui.containers.menus.Menu;
import components.ConfigDialog;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;

@:build(haxe.ui.ComponentBuilder.build("ui/main-view.xml"))
class MainView extends VBox {
    public function new() {
        super();
        config.onClick = function(e) {
            var dialog = new ConfigDialog();
            dialog.showDialog();
        }
    }
}