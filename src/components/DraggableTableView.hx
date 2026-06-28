package components;

import haxe.ui.data.ArrayDataSource;
import haxe.ui.containers.TableView;
import haxe.ui.events.MouseEvent;
import haxe.ui.core.ItemRenderer;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObjectContainer;
import openfl.Lib;

class DraggableTableView extends TableView {
    // I lowkey need to clean this up..
    // This is future me. aw HELL NAH I AINT CLEANIN THIS SHIT UP. I'm too lazy for allat.
    var dragIndex:Int = -1;
    var dropIndex:Int = -1;
    var isDragging:Bool = false;
    var mouseDownX:Float = 0;
    var mouseDownY:Float = 0;
    var dragThreshold:Float = 5;
    var grabOffsetX:Float = 0;
    var grabOffsetY:Float = 0;
    var ghostBitmap:Bitmap = null;

    public var onDataChange:Void->Void = null;

    public function new(?onDataChange:Void->Void = null) {
        super();
        this.onDataChange = onDataChange;

        registerEvent(MouseEvent.MOUSE_DOWN, function(e:MouseEvent) {
            var renderers = findComponentsUnderPoint(e.screenX, e.screenY, ItemRenderer);
            if (renderers.length > 0) {
                var renderer = cast(renderers[0], ItemRenderer);
                dragIndex = renderer.itemIndex;
                mouseDownX = e.screenX;
                mouseDownY = e.screenY;
                grabOffsetX = e.screenX - renderer.screenLeft;
                grabOffsetY = e.screenY - renderer.screenTop;
            }
        });

        haxe.ui.core.Screen.instance.registerEvent(MouseEvent.MOUSE_MOVE, function(e:MouseEvent) {
            if (dragIndex < 0) return;

            if (!isDragging) {
                var dx = e.screenX - mouseDownX;
                var dy = e.screenY - mouseDownY;
                if (Math.sqrt(dx * dx + dy * dy) < dragThreshold) return;
                isDragging = true;
                var renderers = findComponentsUnderPoint(mouseDownX, mouseDownY, ItemRenderer);
                if (renderers.length > 0)
                    createGhost(cast(renderers[0], ItemRenderer), mouseDownX - grabOffsetX, mouseDownY - grabOffsetY);
            }

            if (ghostBitmap != null) {
                ghostBitmap.x = e.screenX - grabOffsetX;
                ghostBitmap.y = e.screenY - grabOffsetY;
            }

            // only update drop target if mouse is over this table
            if (e.screenX >= screenLeft && e.screenX <= screenLeft + width &&
                e.screenY >= screenTop && e.screenY <= screenTop + height) {
                var renderers = findComponentsUnderPoint(e.screenX, e.screenY, ItemRenderer);
                if (renderers.length > 0) {
                    dropIndex = cast(renderers[0], ItemRenderer).itemIndex;
                    selectedIndex = dropIndex;
                }
            } else {
                dropIndex = -1;
            }
        });

        haxe.ui.core.Screen.instance.registerEvent(MouseEvent.MOUSE_UP, function(e:MouseEvent) {
            clearGhost();

            if (!isDragging || dragIndex < 0 || dropIndex < 0 || dragIndex == dropIndex) {
                resetTableView();
                return;
            }
        
            var ds:ArrayDataSource<Dynamic> = cast dataSource;
        
            var draggedItem = ds.get(dragIndex);
            var targetItem = ds.get(dropIndex);
        
            @:privateAccess {
                ds._array.remove(draggedItem);
                var rawTargetIndex = ds._array.indexOf(targetItem);

                var insertIndex = (dragIndex < dropIndex) ? rawTargetIndex + 1 : rawTargetIndex;
                ds._array.insert(insertIndex, draggedItem);

                if (ds._filteredArray != null) {
                    ds._filteredArray.remove(draggedItem);
                    var filteredTargetIndex = ds._filteredArray.indexOf(targetItem);
                    var filteredInsertIndex = (dragIndex < dropIndex) ? filteredTargetIndex + 1 : filteredTargetIndex;
                    ds._filteredArray.insert(filteredInsertIndex, draggedItem);
                }
            
                ds.handleChanged();
            }
        
            selectedIndex = dropIndex;
            resetTableView();
        
            if (onDataChange != null) onDataChange();
        });
    }

    function createGhost(renderer:ItemRenderer, x:Float, y:Float) {
        clearGhost();
        var sprite = cast(renderer, DisplayObjectContainer);
        var bd = new BitmapData(Std.int(renderer.width), Std.int(renderer.height), true, 0x00000000);
        bd.draw(sprite);
        ghostBitmap = new Bitmap(bd);
        ghostBitmap.x = x;
        ghostBitmap.y = y;
        ghostBitmap.alpha = 0.7;
        Lib.current.stage.addChild(ghostBitmap);
    }

    function clearGhost() {
        if (ghostBitmap != null) {
            Lib.current.stage.removeChild(ghostBitmap);
            ghostBitmap = null;
        }
    }

    function resetTableView() {
        dragIndex = -1;
        dropIndex = -1;
        isDragging = false;
    }
}