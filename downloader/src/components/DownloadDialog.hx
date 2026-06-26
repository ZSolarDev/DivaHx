package components;

import sys.io.File;
import haxe.ui.components.Button;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.containers.ScrollView;
import haxe.Exception;
import hxFileManager.FileManager;
import openfl.events.Event;
import haxe.ui.components.Spinner;
import haxe.ui.components.HorizontalProgress;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.geom.Matrix;
import openfl.display.Shape;
import haxe.ui.components.Image;
import openfl.display.BitmapData;
import sys.FileSystem;
import haxe.io.Path;
import hxFileManager.HttpManager;
import sys.thread.Thread;
import haxe.ui.components.Label;
import haxe.ui.containers.dialogs.Dialog;
import openfl.Lib;
import haxe.ui.events.MouseEvent;

using StringTools;

class DownloadDialog extends Dialog {
    public var spinner:Spinner;
    public var progress:HorizontalProgress;
    public var infoText:Label;
    public var modImage:Image;

    var pendingCur:Float = 0;
    var pendingTotal:Float = 0;
    var hasPendingUpdate:Bool = false;

    public function new(?fileIdx:Int = 0) {
        super();
        try {
            this.draggable = false;
            this.centerDialog = false;
            width = 400;
            height = 550;
            onDialogClosed = (_) -> {
                Sys.exit(0);
            }

            haxe.Timer.delay(() -> {
                Lib.application.window.stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
            }, 3000);

            if (isDma) {
                if (dmaMod.files.length == 1) {
                    beginDownload(0);
                } else {
                    BitmapData.loadFromFile(dmaMod.images[0]).onComplete((bitmapData:BitmapData) -> {
                        var newData:BitmapData = roundCorners(bitmapData, 35);
                        modImage = new Image();
                        modImage.resource = newData;
                        modImage.scaleMode = 'fitinside';
                        modImage.width = width - 20;
                        modImage.horizontalAlign = 'center';
                        dialogContent.addComponent(modImage);
                        showFileChooser();
                    }).onError((error) -> {
                        trace(error);
                        showFileChooser();
                    });
                }
            }
        } catch (e) {
            throwError(e);
        }
    }

    function showFileChooser() {
        this.title = 'Choose a file to download: ${dmaMod.name}';

        var label = new Label();
        label.horizontalAlign = 'center';
        label.styleString = 'font-size:16px; color:#FFFFFF;';
        label.text = 'This mod has multiple files. Pick one:';
        dialogContent.addComponent(label);

        var scrollView:ScrollView = new ScrollView();
        scrollView.width = width - 20;
        scrollView.height = dialogContent.height - modImage.height - label.height - 30;
        scrollView.horizontalAlign = 'center';
        scrollView.verticalAlign = 'bottom';
        scrollView.horizontalScrollPolicy = 'never';
        dialogContent.addComponent(scrollView);

        var filesContainer:VBox = new VBox();
        filesContainer.width = width - 30;
        filesContainer.horizontalAlign = 'center';
        filesContainer.styleString = 'vertical-spacing: 15px;';
        scrollView.addComponent(filesContainer);

        for (i in 0...dmaMod.files.length) {
            var idx = i;
            var fileBox:HBox = new HBox();
            fileBox.width = width - 30;

            var fileLabel = new Label();
            fileLabel.text = dmaMod.file_names[idx];
            fileLabel.horizontalAlign = 'center';
            fileLabel.verticalAlign = 'center';
            fileLabel.percentWidth = 70;
            fileBox.addComponent(fileLabel);

            var downloadButton = new Button();
            downloadButton.text = 'Download';
            downloadButton.percentWidth = 30;
            downloadButton.onClick = (_) -> {
                beginDownload(idx);
            }
            fileBox.addComponent(downloadButton);

            filesContainer.addComponent(fileBox);
        }
    }

    function beginDownload(fileIdx:Int) {
        dialogContent.removeAllComponents();

        spinner = new Spinner();
        spinner.styleString = 'filter: tint(#F6871F, 1)';
        spinner.width = 64;
        spinner.height = 64;
        spinner.horizontalAlign = 'center';
        dialogContent.addComponent(spinner);

        BitmapData.loadFromFile(dmaMod.images[0]).onComplete((bitmapData:BitmapData) -> {
            var newData:BitmapData = roundCorners(bitmapData, 35);
            modImage = new Image();
            modImage.resource = newData;
            modImage.scaleMode = 'fitinside';
            modImage.width = width - 20;
            modImage.horizontalAlign = 'center';
            dialogContent.addComponent(modImage);
            loadDialogBody();
        }).onError((error) -> {
            trace(error);
            loadDialogBody();
        });

        var fileName = dmaMod.file_names[fileIdx];
        fileName = fileName.split('/').pop();
        fileName = fileName.split('\\').pop();
        fileName = fileName.replace(':', ';');
        fileName = fileName.replace('*', '');
        fileName = fileName.replace('?', '');
        fileName = fileName.replace('"', "'");
        fileName = fileName.replace('<', '(');
        fileName = fileName.replace('>', ')');
        fileName = fileName.replace('|', ';');

        this.title = 'Downloading ${dmaMod.name} ($fileName)...';
        var dir = createTempDir();

        Thread.create(() -> {
            try {
                HttpManager.downloadTo('https://divamodarchive.com/api/v1/posts/${dmaMod.id}/download/$fileIdx', Path.join([dir, fileName]), new Map(),
                    (cur, total) -> {
                        try {
                            pendingCur = cur;
                            pendingTotal = total;
                            hasPendingUpdate = true;
                        } catch (e) {
                            throwError(e);
                        }
                    }, () -> {
                        onSuccess(Path.join([dir, fileName]), dir);
                    }, (e) -> {
                        throwError(e);
                    },
                    500 * 1024 * 1024
                );
            } catch (e) {
                throwError(e);
            }
        });
    }

    public function loadDialogBody() {
        dialogContent.removeComponent(spinner);

        var modName:Label = new Label();
        modName.horizontalAlign = 'center';
        modName.styleString = 'font-size:20px; color:#FFFFFF;';
        modName.text = truncateToFitWidth(dmaMod.name, width, 20);
        dialogContent.addComponent(modName);
        
        progress = new HorizontalProgress();
        progress.horizontalAlign = 'center';
        progress.width = width - 20;
        progress.height = 30;
        progress.styleNames = 'orange';
        dialogContent.addComponent(progress);

        infoText = new Label();
        infoText.horizontalAlign = 'center';
        infoText.text = 'Downloading...';
        dialogContent.addComponent(infoText);
    }

    function onSuccess(archivePath:String, archiveFolder:String = null) {
        try {
            Lib.application.window.stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            infoText.text = 'Extracting...';
            
            var destDir = Path.join([mmModPath, dmaMod.name]);
            @:privateAccess FileManager.removePath(destDir);

            var logPath = '7zLog(${dmaMod.name}).log';

            Sys.command('start "" cmd /c ""7z.exe" x "$archivePath" -o"$mmModPath" -y> "$logPath" 2>&1"');

            var elapsedMs = 0;
            var pollIntervalMs = 100;
            var timeoutMs = 120000;
            var poller:haxe.Timer = null;

            poller = new haxe.Timer(pollIntervalMs);
            poller.run = () -> {
                elapsedMs += pollIntervalMs;

                var done = false;
                if (FileSystem.exists(logPath)) {
                    try {
                        var logContent = File.getContent(logPath);
                        if (logContent.indexOf('Everything is Ok') != -1)
                            done = true;
                    } catch (e) {} // file might be mid-write/locked by 7z, just try again next tick
                }

                if (done) {
                    poller.stop();
                    try {
                        FileSystem.deleteFile(logPath);
                        FileSystem.deleteFile(archivePath);
                        if (archiveFolder != null) FileSystem.deleteDirectory(archiveFolder);
                    } catch (e) {}
                    hideDialog('{{ok}}');
                    success();
                } else if (elapsedMs >= timeoutMs) {
                    poller.stop();
                    hideDialog('{{ok}}');
                    throwError(new Exception(
                        'Mod extraction failed or timed out! You can find the downloaded file at: "$archivePath"' +
                        (FileSystem.exists(logPath) ? ' You can find the extraction log at: $logPath' : '')
                    ));
                }
            }
        } catch (e) {
            try {
                FileSystem.deleteFile(archivePath);
                if (archiveFolder != null) FileSystem.deleteDirectory(archiveFolder);
            } catch (e) {
                throwError(new Exception(
                'Mod extraction and cleanup failed! ' + e.message +
                (FileSystem.exists('7zLog(${dmaMod.name}).log') ? ' You can find the extraction log at: 7zLog(${dmaMod.name}).log' : '')
            ));
            }
            throwError(new Exception(
                'Mod extraction failed! ' + e.message +
                (FileSystem.exists('7zLog(${dmaMod.name}).log') ? ' You can find the extraction log at: 7zLog(${dmaMod.name}).log' : '')
            ));
        }
    }

    function createTempDir(prefix:String = 'dhx_download_'):String {
        var baseTemp = Sys.getEnv("TEMP");
        if (baseTemp == null) baseTemp = Sys.getEnv("TMP");
        if (baseTemp == null) baseTemp = './';

        var randomSuffix = StringTools.hex(Std.random(99999), 8);
        var tempDir = Path.join([baseTemp, prefix + randomSuffix]);

        // Extremely unlikely to collide, but just in case
        while (FileSystem.exists(tempDir)) {
            randomSuffix = StringTools.hex(Std.random(99999), 8);
            tempDir = Path.join([baseTemp, prefix + randomSuffix]);
        }

        if (tempDir.contains('\\')) tempDir = tempDir.replace('\\', '/');
        if (!tempDir.endsWith('/')) tempDir += '/';

        FileSystem.createDirectory(tempDir);
        return tempDir;
    }

    public static function formatBytes(bytes:Float):String {
        if (bytes < 1024)
            return Std.int(bytes) + ' Bytes';
        else if (bytes < 1024 * 1024)
            return Std.string(Math.round(bytes / 1024 * 100) / 100) + ' KB';
        else if (bytes < 1024 * 1024 * 1024)
            return Std.string(Math.round(bytes / (1024 * 1024) * 100) / 100) + ' MB';
        else
            return Std.string(Math.round(bytes / (1024 * 1024 * 1024) * 100) / 100) + ' GB';
    }

    public function roundCorners(source:BitmapData, cornerRadius:Float):BitmapData {
        var shape = new Shape();
        shape.graphics.beginBitmapFill(source, new Matrix(), false, true);

        var ellipseSize = cornerRadius * 2;
        shape.graphics.drawRoundRect(0, 0, source.width, source.height, ellipseSize, ellipseSize);
        shape.graphics.endFill();

        var roundedData = new BitmapData(source.width, source.height, true, 0x00000000);
        roundedData.draw(shape);

        return roundedData;
    }

    public function truncateToFitWidth(text:String, maxWidth:Float, fontSize:Int):String {
        if (text == null || text == "") return "";

        var measurer = new TextField();
        var format = new TextFormat(null, cast fontSize * 1.2);
        measurer.defaultTextFormat = format;
        measurer.text = text;

        if (measurer.textWidth <= maxWidth)
            return text;

        var truncated = text;
        while (measurer.textWidth > maxWidth && truncated.length > 0) {
            truncated = truncated.substr(0, truncated.length - 1);
            measurer.text = truncated + "...";
        }

        return measurer.text;
    }

    function onEnterFrame(e:Event) {
        if (hasPendingUpdate) {
            hasPendingUpdate = false;
            if (progress != null && pendingTotal > 0) {
                var pct = (pendingCur / pendingTotal) * 100;
                if (pct >= 0 && pct <= 100 && !Math.isNaN(pct))
                    progress.pos = pct;
            }
            if (infoText != null)
                infoText.text = '${formatBytes(pendingCur)} / ${formatBytes(pendingTotal)}';
        }
    }

    override function disposeComponent() {
        super.disposeComponent();
        Lib.application.window.stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
    }
}
