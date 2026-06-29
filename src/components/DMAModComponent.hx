package components;

import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.filters.BlurFilter;
import haxe.ui.containers.Box;
import backend.online.dma.DMAModAuthor;
import openfl.display.BitmapData;
import haxe.ui.containers.Absolute;
import haxe.ui.components.Spinner;
import haxe.ui.components.Image;
import backend.utils.Update;
import backend.utils.Misc;
import haxe.ui.core.Screen;
import haxe.ui.components.Label;
import backend.online.dma.DMAMod;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.components.Spacer;
import components.dialogs.DMAModInfoDialog;

using StringTools;

class DMAModComponent extends VBox {
    public var imageBox:HBox;
    public var abs:Absolute;
    public var spinner:Spinner;
    public var infoBox:VBox;
    public var modImage:Image;
    public var authorBox:HBox;
    public var mainBox:HBox;
    public var mod:DMAMod;
    public var authorImage:Image;

    public function new(mod:DMAMod, idx:Int = 0) {
        super();
        this.mod = mod;
        onClick = (_) -> {
            var dialog = new DMAModInfoDialog(mod);
            dialog.showDialog();
        }
        width = Screen.instance.width * getScaleValue(Screen.instance.width);
        height = Screen.instance.height * 0.4;
        styleString = 'border:3px solid #F6871F; background-color:#F6871F; background-opacity:.2; border-radius:10px; clip:true;';
        imageBox = new HBox();
        imageBox.percentWidth = 100;
        imageBox.componentWidth = width;
        imageBox.width = width;
        imageBox.percentHeight = 70;
        imageBox.componentHeight = height * 0.7;
        imageBox.height = height * 0.7;
        abs = new Absolute();
        abs.width = width;
        abs.height = height;
        abs.componentWidth = width;
        abs.componentHeight = height;
        spinner = new Spinner();
        spinner.styleString = 'filter: tint(#F6871F, 1)';
        spinner.width = 32;
        spinner.height = 32;
        spinner.top = imageBox.height / 2 - 16;
        spinner.left = imageBox.width / 2 - 16;
        abs.addComponent(spinner);
        imageBox.addComponent(abs);
        addComponent(imageBox);
        infoBox = new VBox();
        infoBox.percentWidth = 100;
        infoBox.percentHeight = 30;
        infoBox.styleString = 'padding:5px; spacing:5px; border:3px solid #F6871F; border-bottom-left-radius:7px; border-bottom-right-radius:7px;';
        var modName:Label = new Label();
        modName.horizontalAlign = 'center';
        modName.styleString = 'font-size:20px; color:#FFFFFF;';
        modName.text = Misc.truncateToFitWidth(mod.name, infoBox.width, 20);
        infoBox.addComponent(modName);
        mainBox = new HBox();
        mainBox.styleString = 'padding:5px; spacing:5px;';
        mainBox.verticalAlign = 'center';
        mainBox.width = infoBox.width;
        infoBox.addComponent(mainBox);
        if (mod.authors.length > 1) {
            var modAuthors:Label = new Label();
            modAuthors.text = 'Uploaded by ${mod.authors[0].display_name.trim()} and ${mod.authors.length - 1} more';
            modAuthors.verticalAlign = 'center';
            mainBox.addComponent(modAuthors);
            loadModData();
        } else {
            loadAuthor(mod.authors[0]);
        }
        addComponent(infoBox);

        Update.register(this, (_) -> {
            width = Screen.instance.width * getScaleValue(Screen.instance.width);
            height = Screen.instance.height * 0.4;
            imageBox.width = width;
            imageBox.componentWidth = width;
            imageBox.height = height * 0.7;
            imageBox.componentHeight = height * 0.7;
            abs.width = width;
            abs.height = height;
            abs.componentWidth = width;
            abs.componentHeight = height;
            spinner.top = imageBox.height / 2 - 16;
            spinner.left = imageBox.width / 2 - 16;
            if (modImage != null) {
                modImage.width = imageBox.width - 20;
                modImage.height = imageBox.height - 20;
            }
            if (mainBox != null)
                mainBox.width = infoBox.width;
            modName.text = Misc.truncateToFitWidth(mod.name.trim(), width, 20);
        });

        haxe.Timer.delay(() -> {
            loadImage(mod.images[0]);
        }, 100 + (idx * 100));
    }

    public function loadModData() {
        var spacer:Spacer = new Spacer();
        spacer.percentWidth = 100;
        mainBox.addComponent(spacer);

        var dataBox:HBox = new HBox();
        dataBox.styleString = 'padding:5px; spacing:5px;';
        dataBox.verticalAlign = 'center';

        var data:Label = new Label();
        data.text = '${((mod.post_type == 'Ui' ? 'UI' : mod.post_type))}\n${mod.download_count} Downloads • ${mod.like_count} Like${((mod.like_count == 1) ? '' : 's')}';
        data.verticalAlign = 'center';
        data.textAlign = 'right';
        dataBox.addComponent(data);

        mainBox.addComponent(dataBox);
    }

    public function loadAuthor(author:DMAModAuthor) {
        BitmapData.loadFromFile(author.avatar).onComplete((bitmapData:BitmapData) -> {
            authorBox = new HBox();
            authorBox.styleString = 'padding:5px; spacing:5px;';
            authorBox.horizontalAlign = 'left';
            var newData = Misc.circleify(bitmapData);
            bitmapData.dispose();
            authorImage = new Image();
            authorImage.resource = newData;
            authorImage.width = 32;
            authorImage.height = 32;
            authorImage.verticalAlign = 'center';
            authorImage.horizontalAlign = 'left';
            authorBox.addComponent(authorImage);
            var authorName:Label = new Label();
            authorName.text = author.display_name.trim();
            authorName.verticalAlign = 'center';
            authorName.horizontalAlign = 'left';
            authorBox.addComponent(authorName);
            mainBox.addComponent(authorBox);
            loadModData();
        }).onError((error) -> {
            authorBox = new HBox();
            authorBox.styleString = 'padding:5px; spacing:5px;';
            authorBox.horizontalAlign = 'left';
            var authorName:Label = new Label();
            authorName.text = author.display_name.trim();
            authorName.verticalAlign = 'center';
            authorName.horizontalAlign = 'left';
            authorBox.addComponent(authorName);
            mainBox.addComponent(authorBox);
            loadModData();
        });
    }

    public function loadImage(url:String) {
        BitmapData.loadFromFile(url).onComplete((bitmapData:BitmapData) -> {
            var resized = Misc.resizeBitmap(bitmapData, imageBox.width * 1.5 - 20, imageBox.height * 1.5 - 20);
            bitmapData.dispose();

            imageBox.padding = 10;
            imageBox.paddingTop = 15;
            var processedData:BitmapData = mod.explicit
                ? Misc.roundCorners(Misc.blurBitmap(resized), 8)
                : Misc.roundCorners(resized, 8);
            resized.dispose();

            imageBox.removeAllComponents();
            modImage = new Image();
            modImage.resource = processedData;
            modImage.scaleMode = 'fitinside';
            modImage.width = imageBox.width - 20;
            modImage.height = imageBox.height - 20;
            modImage.left = 0;
            modImage.top = 0;

            var stack = new Absolute();
            stack.width = imageBox.width - 20;
            stack.height = imageBox.height - 20;
            stack.horizontalAlign = 'center';
            stack.verticalAlign = 'center';
            stack.addComponent(modImage);
            imageBox.addComponent(stack);

            if (mod.explicit) {
                haxe.Timer.delay(() -> {
                    var boxW = imageBox.width - 15;
                    var boxH = imageBox.height - 15;
                
                    var scale = Math.min(boxW / modImage.originalWidth, boxH / modImage.originalHeight);
                    var renderedW = modImage.originalWidth * scale;
                    var renderedH = modImage.originalHeight * scale;
                
                    var overlay = new Box();
                    overlay.styleString = 'background-color:#000000; background-opacity:.55; border-radius:15px;';
                    overlay.width = renderedW;
                    overlay.height = renderedH;
                    overlay.left = (stack.width - renderedW) / 2;
                    overlay.top = (stack.height - renderedH) / 2;
                    stack.addComponent(overlay);
                
                    var nsfwLabel = new Label();
                    nsfwLabel.text = 'Explicit';
                    nsfwLabel.styleString = 'font-size:20px; color:#FFFFFF; font-weight:bold;';
                    nsfwLabel.left = overlay.left + 15;
                    nsfwLabel.top = overlay.top + 10;
                    stack.addComponent(nsfwLabel);
                }, 50);
            }
        }).onError((error) -> {

        });
    }

    public function getScaleValue(x:Float):Float {
        return (5.0902242040635786e-12 * x * x * x) + (-3.7549767260781715e-08 * x * x) + (9.3045094388797194e-05 * x) + 0.23974884399240393;
    }

    public function preDispose() {
        Update.unregister(this);
        modImage?.resource?.toImageData()?.dispose();
        if (modImage != null) modImage.resource = null;
        authorImage?.resource?.toImageData()?.dispose();
        if (authorImage != null) authorImage.resource = null;
    }
}