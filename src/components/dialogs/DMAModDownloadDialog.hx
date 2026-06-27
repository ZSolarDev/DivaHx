package components.dialogs;

import backend.online.dma.DMAMod;
import haxe.ui.components.Button;
import backend.online.download.DMADownloader;

class DMAModDownloadDialog extends ScrollDialog {
    override public function new(messageTitle:String = '', message:String = '', isError:Bool = false, mod:DMAMod) {
        super(messageTitle, message, true);

        if (isError && mod != null) {
            var retryButton = new Button();
            retryButton.text = 'Retry';
            retryButton.onClick = (_) -> {
                DMADownloader.downloadMod(mod);
                hideDialog('{{close}}');
            }
            addFooterComponent(retryButton);
        }
    }
}