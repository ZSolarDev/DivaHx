package components.dialogs;

import backend.online.gamebanana.GBMod;
import backend.online.gamebanana.GBModData;
import haxe.ui.components.Button;
import backend.online.download.GBDownloader;

class GBModDownloadDialog extends ScrollDialog {
    override public function new(messageTitle:String = '', message:String = '', isError:Bool = false, mod:GBMod, modData:GBModData) {
        super(messageTitle, message, true);

        if (isError && mod != null && modData != null) {
            var retryButton = new Button();
            retryButton.text = 'Retry';
            retryButton.onClick = (_) -> {
                GBDownloader.downloadMod(mod, modData);
                hideDialog('{{close}}');
            }
            addFooterComponent(retryButton);
        }
    }
}