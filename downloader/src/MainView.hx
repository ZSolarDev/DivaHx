package;

import haxe.ui.Toolkit;
import components.DownloadDialog;
import dma.DMAMod;
import haxe.ui.containers.dialogs.Dialog;
import openfl.events.Event;
import openfl.Lib;
import openfl.events.MouseEvent as OpenFLMouseEvent; 
import haxe.ui.events.MouseEvent as HaxeUIMouseEvent; 
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.VBox;

class MainView extends VBox {
    public var window = Lib.application.window;
    public var dialog:DownloadDialog;

    public function new() {
        try {
            super();
            
            Toolkit.styleSheet.parse('
                .horizontal-progress.orange .progress-value {
                    background: #F6871F #DF641D;
                }
            ');
            window.borderless = true;
            
            // Load dialog
            loadDialog();

            // Window dragging
            loadWindowDrag();
        } catch (e) {
            throwError(e);
        }
    }

    public function loadWindowDrag() {
        var isDragging:Bool = false;
        var dragOffsetX:Float = 0;
        var dragOffsetY:Float = 0;

        dialog.registerEvent(HaxeUIMouseEvent.MOUSE_DOWN, (e:HaxeUIMouseEvent) -> {
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

    public function loadDialog() {
        dialog = new DownloadDialog();
        dialog.showDialog();
    }
}