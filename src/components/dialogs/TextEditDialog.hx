package components.dialogs;

import haxe.ui.components.TextArea;
import haxe.ui.events.UIEvent;
import haxe.ui.components.Button;
import haxe.ui.core.Screen;
import haxe.ui.containers.Box;
import haxe.ui.containers.ScrollView;
import haxe.ui.containers.VBox;
import haxe.ui.containers.dialogs.Dialog;

using StringTools;

class TextEditDialog extends Dialog {
    public var mainBox:VBox;
    public var mainVBox:VBox;
    public var textAreaScrollView:ScrollView;
    public var textArea:TextArea;
    public var mainBoxVBox:VBox;
    public var descBox:Box;
    public var textData:String;

    override public function new(dialogTitle:String = '', textData:String = '', hasSaveButton:Bool = false, ?saveFunc:String->Void) {
        super();
        this.title = dialogTitle;
        this.textData = textData;
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
        if (hasSaveButton) {
            var saveButton = new Button();
            saveButton.text = 'Save';
            saveButton.onClick = (_) -> {
                if (saveFunc != null) {
                    saveFunc(textArea.text);
                    saveButton.text = 'Saved!';
                } else 
                    saveButton.text = 'Failed to save...';
                saveButton.disabled = true;
                haxe.Timer.delay(() -> {
                    saveButton.text = 'Save';
                    saveButton.disabled = false;
                }, 1000);
            }
            addFooterComponent(saveButton);
        }
    }
    
    public function onResize() {
        width = Screen.instance.width * 0.7;
        height = Screen.instance.height * 0.7;
        textAreaScrollView.width = width - 12;
        textAreaScrollView.height = height - top - 5;
        mainBox.width = width - 12;
        descBox.width = mainBox.width - 55;
        textArea.width = descBox.width - 10;
        textArea.height = textAreaScrollView.height / 1.2;
        centerDialogComponent(this, true);
    }

    public function load() {
        mainBox = new VBox();
        mainBox.styleString = 'padding:5px; spacing:5px;';
        mainBox.horizontalAlign = 'left';
        mainBox.verticalAlign = 'center';
        dialogContent.addComponent(mainBox);
        
        textAreaScrollView = new ScrollView();
        textAreaScrollView.width = width - 12;
        textAreaScrollView.height = height - top - 5;
        textAreaScrollView.horizontalScrollPolicy = 'never';
        mainBox.addComponent(textAreaScrollView);
        
        mainVBox = new VBox();
        mainVBox.width = width - 12;
        mainVBox.styleString = 'padding:20px; spacing:10px;';
        textAreaScrollView.addComponent(mainVBox);

        descBox = new Box();
        descBox.width = mainVBox.width - 55;
        descBox.padding = 5;
        descBox.styleString = 'background-color:#525252; background-opacity:.2; border-radius:10px;';
        mainVBox.addComponent(descBox);
        textArea = new TextArea();
        textArea.text = textData;
        textArea.width = descBox.width - 10;
        textArea.height = textAreaScrollView.height - 10;
        textArea.getTextDisplay().textField.selectable = true;
        textArea.getTextDisplay().textField.mouseEnabled = true;
        textArea.mouseEnabled = true;
        descBox.addComponent(textArea);

        onResize();
    }
}