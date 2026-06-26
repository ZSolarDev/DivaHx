package components.dialogs;

import backend.online.download.DMADownloader;
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

class DMAModInfoDialog extends Dialog {
    public var mod:DMAMod;
    public var modInfo:VBox;
    public var curImageIdx:Int = 0;
    public var descScrollView:ScrollView;
    public var mainVBox:VBox;
    public var titleBox:Box;
    public var descBox:Box;
    public var depsBox:VBox;
    public var imageBox:VBox;
    public var imageDisplayBox:HBox;
    public var curImage:Image;
    public var spinner:Spinner;
    public var curImageText:Label;

    override public function new(mod:DMAMod) {
        super();
        this.mod = mod;
        title = mod.name;
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
        downloadButton.text = 'Download (${(mod.files.length == 1 ? (Misc.formatBytes(mod.file_sizes[0])) : mod.files.length + ' Files')}) ' + (MainView.allMods.contains(mod.name) ? '(Installed' + (!MainView.enabledMods.contains(mod.name) ? ', Disabled' : '') + ')' : '');
        downloadButton.onClick = (_) -> {
            FileSystem.createDirectory('./mods');
            DMADownloader.downloadMod(mod);
        }
        addFooterComponent(downloadButton);
        var modInfoButton = new Button();
        modInfoButton.text = 'Mod Info';
        modInfoButton.onClick = (_) -> {
            Lib.getURL(new URLRequest('https://divamodarchive.com/post/${mod.id}'));
        }
        addFooterComponent(modInfoButton);
    }

    public function loadImage() {
        if (mod.images.length == 0) {
            imageDisplayBox.removeAllComponents();
            var noImages = new Label();
            noImages.text = "No images available.";
            noImages.horizontalAlign = 'center';
            noImages.styleString = 'color:#FFFFFF;';
            imageDisplayBox.addComponent(noImages);
            return;
        }

        BitmapData.loadFromFile(mod.images[curImageIdx]).onComplete((bitmapData:BitmapData) -> {
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
                curImageIdx = (curImageIdx - 1 + mod.images.length) % mod.images.length;
                loadImage();
            }
            if (mod.images.length == 1)
                prevImageButton.disabled = true;
            imageDisplayBox.addComponent(prevImageButton);

            imageDisplayBox.addComponent(curImage);

            var nextImageButton = new Button();
            nextImageButton.text = '>';
            nextImageButton.verticalAlign = 'center';
            nextImageButton.fontSize = 32;
            nextImageButton.onClick = (_) -> {
                curImageIdx = (curImageIdx + 1) % mod.images.length;
                loadImage();
            }
            if (mod.images.length == 1)
                nextImageButton.disabled = true;
            imageDisplayBox.addComponent(nextImageButton);

            curImageText.text = 'Image ${curImageIdx + 1}/${mod.images.length}';

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
        curImageText.styleString = 'font-size:17px; color:#FFFFFF;';
        imageBox.addComponent(curImageText);

        loadImage();
    }

    public function onResize() {
        width = Screen.instance.width * 0.7;
        height = Screen.instance.height * 0.7;
        descScrollView.width = width - 12;
        descScrollView.height = height - top - dialogFooter.height;
        mainVBox.width = width - 12;
        titleBox.width = mainVBox.width - 55;
        descBox.width = mainVBox.width - 55;
        if (depsBox != null)
            depsBox.width = mainVBox.width - 55;
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
        descScrollView.height = height - top - dialogFooter.height;
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
        title.text = mod.name.trim();
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
            desc.htmlText = Misc.markdownToHTMLText(mod.text);
            desc.getTextDisplay().textField.selectable = true;
            desc.getTextDisplay().textField.mouseEnabled = true;
            desc.selectable = true;
            desc.mouseEnabled = true;
        }, 50);

        if (mod.dependencies != null) {
            depsBox = new VBox();
            depsBox.width = mainVBox.width - 55;
            depsBox.padding = 5;
            depsBox.styleString = 'background-color:#525252; background-opacity:.2; spacing:5px; border-radius:10px;';
            mainVBox.addComponent(depsBox);
            var depsGrid:Grid = new Grid();
            depsGrid.columns = 3;
            depsGrid.percentWidth = 100;
            depsGrid.horizontalAlign = 'center';
        
            var anyMissing = false;
            for (dependency in mod.dependencies) {
                var dep:Button = new Button();
                dep.text = dependency.name + (MainView.allMods.contains(dependency.name) ? ' (Installed' + (!MainView.enabledMods.contains(dependency.name) ? ', Disabled' : '') + ')' : '');
                dep.onClick = (_) -> {
                    var dialog = new DMAModInfoDialog(dependency);
                    dialog.showDialog();
                }
                depsGrid.addComponent(dep);
                if (!MainView.allMods.contains(dependency.name))
                    anyMissing = true;
            }
            depsBox.addComponent(depsGrid);
            if (anyMissing) {
                var downloadAll:Button = new Button();
                downloadAll.text = 'Download Missing Dependencies';
                downloadAll.horizontalAlign = 'center';
                downloadAll.onClick = (_) -> {
                    for (dependency in mod.dependencies) {
                        if (!MainView.allMods.contains(dependency.name))
                            DMADownloader.downloadMod(dependency);
                    }
                }
                depsBox.addComponent(downloadAll);
            }
        }

        onResize();
    }
}