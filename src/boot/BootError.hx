package boot;

import openfl.Lib;
import openfl.events.MouseEvent as OpenFLMouseEvent; 
import haxe.ui.events.MouseEvent as HaxeUIMouseEvent; 
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.VBox;

class BootError extends VBox {
    public function new() {
        super();
        var window = Lib.application.window;
        var display = window.display;
        window.borderless = true;
        
        var dialog = Dialogs.messageBox('', '', '', false);
        window.setMinSize(0, 0);
        window.width = 296;
        window.height = 153;
        width = dialog.width;
        height = dialog.height;
        dialog.hideDialog('{{ok}}');
        
        window.x = Std.int((display.bounds.width - window.width) / 2);
        window.y = Std.int((display.bounds.height - window.height) / 2);
        
        var dia = Dialogs.messageBox('Another instance is running!', 'DivaHx Boot Error', 'error', true, (_) -> {
            Sys.exit(1);
        });
        
        dia.draggable = false;
        dia.centerDialog = false;
        dia.screenLeft = -2;
        dia.screenTop = -2;
        dia.x = -2;
        dia.y = -2;


        // Window dragging
        var isDragging:Bool = false;
        var dragOffsetX:Float = 0;
        var dragOffsetY:Float = 0;

        dia.registerEvent(HaxeUIMouseEvent.MOUSE_DOWN, (e:HaxeUIMouseEvent) -> {
            isDragging = true;
            dragOffsetX = e.screenX;
            dragOffsetY = e.screenY;
        });

        Lib.current.stage.addEventListener(OpenFLMouseEvent.MOUSE_MOVE, (e:OpenFLMouseEvent) -> {
            if (isDragging) {
                window.x = Std.int(window.x + (e.stageX - dragOffsetX));
                window.y = Std.int(window.y + (e.stageY - dragOffsetY));
            }
        });

        Lib.current.stage.addEventListener(OpenFLMouseEvent.MOUSE_UP, (e:OpenFLMouseEvent) -> {
            isDragging = false;
        });
    }
}