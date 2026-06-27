package components.dialogs;

import backend.online.gamebanana.GBModData;
import backend.online.gamebanana.GBMod;
import backend.online.download.GBDownloader;
import sys.FileSystem;
import openfl.Lib;
import openfl.net.URLRequest;
import backend.utils.Misc;
import openfl.display.BitmapData;
import haxe.ui.events.UIEvent;
import haxe.ui.components.Spinner;
import haxe.ui.components.Image;
import haxe.ui.components.Button;
import haxe.ui.core.Screen;
import haxe.ui.containers.Box;
import haxe.ui.components.Label;
import haxe.ui.containers.ScrollView;
import haxe.ui.containers.Grid;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import backend.online.dma.DMAMod;
import haxe.ui.containers.dialogs.Dialog;

using StringTools;

class GBModInfoDialog extends Dialog {
    public var mod:GBMod;
    public var modData:GBModData;
    public var modInfo:VBox;
    public var curImageIdx:Int = 0;
    public var descScrollView:ScrollView;
    public var mainVBox:VBox;
    public var titleBox:Box;
    public var descBox:Box;
    public var imageBox:VBox;
    public var imageDisplayBox:HBox;
    public var curImage:Image;
    public var spinner:Spinner;
    public var curImageText:Label;
    public var descText:Label;

    override public function new(mod:GBMod, modData:GBModData) {
        super();
        this.mod = mod;
        this.modData = modData;
        title = mod._sName;
        width = Screen.instance.width * 0.7;
        height = Screen.instance.height * 0.7;
        dialogContent.padding = 0;
        dialogContent.paddingTop = 0;
        dialogContent.paddingBottom = 0;
        dialogContent.paddingLeft = 0;
        dialogContent.paddingRight = 0;
        draggable = false;
        Screen.instance.registerEvent(UIEvent.RESIZE, (_) -> {
            onResize();
        });
        loadModInfo();

        buttons = '{{close}}';
        var downloadButton = new Button();
        var fileKeys = Reflect.fields(modData.filesAFiles);
        var filesLength = fileKeys.length;
        var displaySize = "";

        if (filesLength == 1) {
            var firstFile = Reflect.field(modData.filesAFiles, fileKeys[0]);
            displaySize = Misc.formatBytes64(firstFile._nFilesize);
        } else {
            displaySize = filesLength + ' Files';
        }

        downloadButton.text = 'Download (' + displaySize + ') ' + (MainView.isModInstalled(mod._sName) ? '(Installed' + (!MainView.isModEnabled(mod._sName) ? ', Disabled' : '') + ')' : '');
        downloadButton.onClick = (_) -> {
            GBDownloader.downloadMod(mod, modData);
        }
        addFooterComponent(downloadButton);
        var modInfoButton = new Button();
        modInfoButton.text = 'Mod Info';
        modInfoButton.onClick = (_) -> {
            Lib.getURL(new URLRequest('https://divamodarchive.com/post/${mod._idRow}'));
        }
        addFooterComponent(modInfoButton);
    }

    public function loadImage() {
        if (mod._aPreviewMedia._aImages.length == 0) {
            imageDisplayBox.removeAllComponents();
            var noImages = new Label();
            noImages.text = "No images available.";
            noImages.horizontalAlign = 'center';
            noImages.styleString = 'color:#FFFFFF;';
            imageDisplayBox.addComponent(noImages);
            return;
        }

        BitmapData.loadFromFile('${mod._aPreviewMedia._aImages[curImageIdx]._sBaseUrl}/${mod._aPreviewMedia._aImages[curImageIdx]._sFile}').onComplete((bitmapData:BitmapData) -> {
            var newData:BitmapData = Misc.roundCorners(bitmapData, 35);

            curImage = new Image();
            curImage.resource = newData;
            curImage.scaleMode = 'fitinside';
            curImage.percentWidth = 100;
            curImage.height = Screen.instance.height * 0.3;
            curImage.horizontalAlign = 'center';
            curImage.verticalAlign = 'center';

            imageDisplayBox.removeAllComponents();

            var prevImageButton = new Button();
            prevImageButton.text = '<';
            prevImageButton.verticalAlign = 'center';
            prevImageButton.fontSize = 32;
            prevImageButton.onClick = (_) -> {
                curImageIdx = (curImageIdx - 1 + mod._aPreviewMedia._aImages.length) % mod._aPreviewMedia._aImages.length;
                loadImage();
            }
            if (mod._aPreviewMedia._aImages.length == 1)
                prevImageButton.disabled = true;
            imageDisplayBox.addComponent(prevImageButton);

            imageDisplayBox.addComponent(curImage);

            var nextImageButton = new Button();
            nextImageButton.text = '>';
            nextImageButton.verticalAlign = 'center';
            nextImageButton.fontSize = 32;
            nextImageButton.onClick = (_) -> {
                curImageIdx = (curImageIdx + 1) % mod._aPreviewMedia._aImages.length;
                loadImage();
            }
            if (mod._aPreviewMedia._aImages.length == 1)
                nextImageButton.disabled = true;
            imageDisplayBox.addComponent(nextImageButton);

            curImageText.text = 'Image ${curImageIdx + 1}/${mod._aPreviewMedia._aImages.length}';

        }).onError((_) -> {
            // TODO: handle error
        });
    }

    public function loadImageBox() {
        imageBox = new VBox();
        imageBox.percentWidth = 100;
        imageBox.padding = 5;
        imageBox.styleString = 'background-color:#525252; background-opacity:.2; border-radius:10px;';
        mainVBox.addComponent(imageBox);

        imageDisplayBox = new HBox();
        imageDisplayBox.percentWidth = 100;
        imageDisplayBox.height = Screen.instance.height * 0.35;
        imageDisplayBox.padding = 5;
        imageDisplayBox.styleString = 'background-color:#525252; background-opacity:.2; border-radius:10px;';
        imageDisplayBox.horizontalAlign = 'center';
        imageDisplayBox.verticalAlign = 'center';
        imageBox.addComponent(imageDisplayBox);

        spinner = new Spinner();
        spinner.styleString = 'filter: tint(#F6871F, 1)';
        spinner.width = 32;
        spinner.height = 32;
        spinner.horizontalAlign = 'center';
        spinner.verticalAlign = 'center';
        imageDisplayBox.addComponent(spinner);

        curImageText = new Label();
        curImageText.horizontalAlign = 'center';
        curImageText.text = 'Loading...';
        curImageText.styleString = 'font-size:17px; color:#FFFFFF; padding-bottom:5px;';
        imageBox.addComponent(curImageText);

        if (modData.description != '') {
            descText = new Label();
            descText.horizontalAlign = 'center';
            descText.htmlText = '<i>${modData.description}</i>';
            descText.styleString = 'font-size:15px; color:#E0E0E0;';
            imageBox.addComponent(descText);
        }

        loadImage();
    }

    public function onResize() {
        width = Screen.instance.width * 0.7;
        height = Screen.instance.height * 0.7;
        descScrollView.width = width - 12;
        descScrollView.height = height - top - 5;
        mainVBox.width = width - 12;
        titleBox.width = mainVBox.width - 55;
        descBox.width = mainVBox.width - 55;
        imageBox.width = mainVBox.width - 55;
        imageDisplayBox.height = Screen.instance.height * 0.35;
        if (curImage != null) {
            curImage.height = Screen.instance.height * 0.3;
        }
        centerDialogComponent(this, true);
    }

    public function loadModInfo() {
        // Mod Info
        modInfo = new VBox();
        modInfo.styleString = 'padding:5px; spacing:5px;';
        modInfo.horizontalAlign = 'left';
        modInfo.verticalAlign = 'center';
        dialogContent.addComponent(modInfo);
        
        descScrollView = new ScrollView();
        descScrollView.width = width - 12;
        descScrollView.height = height - top - 5;
        descScrollView.horizontalScrollPolicy = 'never';
        modInfo.addComponent(descScrollView);
        
        mainVBox = new VBox();
        mainVBox.width = width - 12;
        mainVBox.styleString = 'padding:20px; spacing:10px;';
        descScrollView.addComponent(mainVBox);

        // Title
        titleBox = new Box();
        titleBox.width = mainVBox.width - 55;
        titleBox.padding = 5;
        titleBox.styleString = 'background-color:#525252; background-opacity:.2; border-radius:10px;';
        mainVBox.addComponent(titleBox);
        var title = new Label();
        title.styleString = 'font-size:32; color:#FFFFFF;';
        title.text = mod._sName.trim();
        title.textAlign = 'center';
        title.horizontalAlign = 'center';
        title.verticalAlign = 'center';
        titleBox.addComponent(title);

        // Images
        loadImageBox();

        // Description
        descBox = new Box();
        descBox.width = mainVBox.width - 55;
        descBox.padding = 5;
        descBox.styleString = 'background-color:#525252; background-opacity:.2; border-radius:10px;';
        mainVBox.addComponent(descBox);
        var desc = new Label();
        desc.wordWrap = true;
        desc.width = descBox.width;
        descBox.addComponent(desc);

        haxe.Timer.delay(() -> {
            desc.htmlText = modData.text;
            desc.getTextDisplay().textField.selectable = true;
            desc.getTextDisplay().textField.mouseEnabled = true;
            desc.selectable = true;
            desc.mouseEnabled = true;
        }, 50);
        onResize();
    }
}