package components.dialogs;

import lime.system.Clipboard;
import backend.online.download.DMADownloader;
import sys.thread.Thread;
import sys.FileSystem;
import sys.io.File;
import openfl.net.URLRequest;
import openfl.events.TextEvent;
import openfl.Lib;
import openfl.net.URLRequest;
import backend.utils.Misc;
import openfl.display.BitmapData;
import haxe.ui.events.UIEvent;
import haxe.ui.components.Spinner;
import haxe.ui.containers.Absolute;
import haxe.ui.components.Image;
import haxe.ui.components.Spacer;
import haxe.ui.components.Button;
import haxe.ui.core.Screen;
import backend.utils.Update;
import haxe.ui.containers.Box;
import haxe.ui.components.Label;
import haxe.ui.containers.ScrollView;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import backend.online.dma.DMAMod;
import haxe.ui.containers.dialogs.Dialog;

using StringTools;

class ScrollDialog extends Dialog {
    public var mainBox:VBox;
    public var mainVBox:VBox;
    public var descScrollView:ScrollView;
    public var mainBoxVBox:VBox;
    public var descBox:Box;
    public var description:String;

    override public function new(dialogTitle:String = '', description:String = '', hasCopyButton:Bool = false) {
        super();
        this.title = dialogTitle;
        this.description = description;
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
        load();

        buttons = '{{close}}';
        if (hasCopyButton) {
            var copyButton = new Button();
            copyButton.text = 'Copy to clipboard';
            copyButton.onClick = (_) -> {
                Clipboard.text = description;
                copyButton.text = 'Copied!';
                copyButton.disabled = true;
                haxe.Timer.delay(() -> {
                    copyButton.text = 'Copy to clipboard';
                    copyButton.disabled = false;
                }, 1000);
            }
            addFooterComponent(copyButton);
        }
    }
    
    public function onResize() {
        width = Screen.instance.width * 0.7;
        height = Screen.instance.height * 0.7;
        descScrollView.width = width - 12;
        descScrollView.height = height - top - dialogFooter.height;
        mainBox.width = width - 12;
        descBox.width = mainBox.width - 55;
        centerDialogComponent(this, true);
    }

    public function load() {
        mainBox = new VBox();
        mainBox.styleString = 'padding:5px; spacing:5px;';
        mainBox.horizontalAlign = 'left';
        mainBox.verticalAlign = 'center';
        dialogContent.addComponent(mainBox);
        
        descScrollView = new ScrollView();
        descScrollView.width = width - 12;
        descScrollView.height = height - top - dialogFooter.height;
        descScrollView.horizontalScrollPolicy = 'never';
        mainBox.addComponent(descScrollView);
        
        mainVBox = new VBox();
        mainVBox.width = width - 12;
        mainVBox.styleString = 'padding:20px; spacing:10px;';
        descScrollView.addComponent(mainVBox);

        // Description
        descBox = new Box();
        descBox.width = mainVBox.width - 55;
        descBox.padding = 5;
        descBox.styleString = 'background-color:#525252; background-opacity:.2; border-radius:10px;';
        mainVBox.addComponent(descBox);
        var desc = new Label();
        desc.htmlText = Misc.markdownToHTMLText(description);
        desc.wordWrap = true;
        desc.width = descBox.width;
        desc.getTextDisplay().textField.selectable = true;
        desc.getTextDisplay().textField.mouseEnabled = true;
        desc.selectable = true;
        desc.mouseEnabled = true;
        descBox.addComponent(desc);

        onResize();
    }
}