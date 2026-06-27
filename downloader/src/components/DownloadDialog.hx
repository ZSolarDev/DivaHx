package components;

import haxe.Json;
import haxe.Int64;
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
import gamebanana.GBMod;
import gamebanana.GBModData;

using StringTools;

class DownloadDialog extends Dialog {
    public var spinner:Spinner;
    public var progress:HorizontalProgress;
    public var infoText:Label;
    public var modImage:Image;
    public var fileIdx:Int = 0;

    var gbFileKeys:Array<String> = [];
    var pendingCur:Int64 = 0;
    var pendingTotal:Int64 = 0;
    var hasPendingUpdate:Bool = false;

    public function new() {
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
                    beginDownload();
                } else {
                    loadModPreviewAndShowChooser();
                }
            } else {
                if (gbModData != null && gbModData.filesAFiles != null)
                    gbFileKeys = Reflect.fields(gbModData.filesAFiles);

                if (gbFileKeys.length == 1)
                    beginDownload();
                else
                    loadModPreviewAndShowChooser();
            }
        } catch (e) {
            throwError(e);
        }
    }

    inline function getModImageUrl():String {
        if (isDma) {
            return dmaMod.images[0];
        } else {
            var preview = gbMod._aPreviewMedia._aImages[0];
            return preview._sBaseUrl + '/' + preview._sFile;
        }
    }

    inline function getModName():String {
        return isDma ? dmaMod.name : gbMod._sName;
    }

    function loadModPreviewAndShowChooser() {
        BitmapData.loadFromFile(getModImageUrl()).onComplete((bitmapData:BitmapData) -> {
            var newData:BitmapData = roundCorners(bitmapData, 35);
            modImage = new Image();
            modImage.resource = newData;
            modImage.scaleMode = 'fitinside';
            modImage.width = width - 20;
            modImage.horizontalAlign = 'center';
            dialogContent.addComponent(modImage);
            showFileChooser();
        }).onError((error) -> {
            showFileChooser();
        });
    }

    function showFileChooser() {
        this.title = 'Choose a file to download: ${getModName()}';

        var label = new Label();
        label.horizontalAlign = 'center';
        label.styleString = 'font-size:16px; color:#FFFFFF;';
        label.text = 'This mod has multiple files. Pick one:';
        dialogContent.addComponent(label);

        var scrollView:ScrollView = new ScrollView();
        scrollView.width = width - 20;
        if (modImage != null) {
            scrollView.height = dialogContent.height - modImage.height - label.height - 30;
        } else {
            scrollView.height = dialogContent.height - label.height - 30;
        }
        scrollView.horizontalAlign = 'center';
        scrollView.verticalAlign = 'bottom';
        scrollView.horizontalScrollPolicy = 'never';
        dialogContent.addComponent(scrollView);

        var filesContainer:VBox = new VBox();
        filesContainer.width = width - 30;
        filesContainer.horizontalAlign = 'center';
        filesContainer.styleString = 'vertical-spacing: 15px;';
        scrollView.addComponent(filesContainer);

        var fileCount = isDma ? dmaMod.files.length : gbFileKeys.length;

        for (i in 0...fileCount) {
            var idx = i;
            var fileBox:HBox = new HBox();
            fileBox.width = width - 30;

            var fileLabel = new Label();
            
            if (isDma)
                fileLabel.text = dmaMod.file_names[idx];
            else {
                var fileInfo:Dynamic = Reflect.field(gbModData.filesAFiles, gbFileKeys[idx]);
                fileLabel.text = fileInfo._sFile;
            }

            fileLabel.horizontalAlign = 'center';
            fileLabel.verticalAlign = 'center';
            fileLabel.percentWidth = 70;
            fileBox.addComponent(fileLabel);

            var downloadButton = new Button();
            downloadButton.text = 'Download';
            downloadButton.percentWidth = 30;
            downloadButton.onClick = (_) -> {
                fileIdx = idx;
                beginDownload();
            }
            fileBox.addComponent(downloadButton);

            filesContainer.addComponent(fileBox);
        }
    }

    function beginDownload() {
        dialogContent.removeAllComponents();

        spinner = new Spinner();
        spinner.styleString = 'filter: tint(#F6871F, 1)';
        spinner.width = 64;
        spinner.height = 64;
        spinner.horizontalAlign = 'center';
        dialogContent.addComponent(spinner);

        BitmapData.loadFromFile(getModImageUrl()).onComplete((bitmapData:BitmapData) -> {
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

        var fileName = '';
        var downloadUrl = '';

        if (isDma) {
            fileName = dmaMod.file_names[fileIdx];
            downloadUrl = 'https://divamodarchive.com/api/v1/posts/${dmaMod.id}/download/$fileIdx';
        } else {
            var fileInfo:Dynamic = Reflect.field(gbModData.filesAFiles, gbFileKeys[fileIdx]);
            fileName = fileInfo._sFile;
            downloadUrl = fileInfo._sDownloadUrl;
        }

        fileName = fileName.split('/').pop();
        fileName = fileName.split('\\').pop();
        fileName = fileName.replace(':', ';');
        fileName = fileName.replace('*', '');
        fileName = fileName.replace('?', '');
        fileName = fileName.replace('"', "'");
        fileName = fileName.replace('<', '(');
        fileName = fileName.replace('>', ')');
        fileName = fileName.replace('|', ';');

        this.title = 'Downloading ${getModName()} ($fileName)...';
        var dir = createTempDir();

        Thread.create(() -> {
            try {
                HttpManager.downloadTo(downloadUrl, Path.join([dir, fileName]), new Map(),
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
        modName.text = truncateToFitWidth(getModName(), width, 20);
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
        var cleanModName = getModName().replace(':', ';').replace('*', '').replace('?', '').replace('"', "'").replace('<', '(').replace('>', ')').replace('|', ';');
        var logPath = 'MREPORT(${cleanModName})';
        
        try {
            Lib.application.window.stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            infoText.text = 'Extracting...';
            
            var destDir = Path.join([mmModPath, cleanModName]);
            @:privateAccess FileManager.removePath(destDir);

            File.saveContent(logPath, '${Json.stringify({
                mod: ((isDma ? dmaMod : gbMod):Dynamic),
                modData: ((isDma ? null : gbModData):Dynamic),
                modType: (isDma ? 'dma' : 'gb'),
                fileIdx: fileIdx,
                archiveFolder: archiveFolder
            }).replace('\n', '')}\n');

            Sys.command('start "" cmd /c ""7z.exe" x "$archivePath" -o"$mmModPath" -y>> "$logPath" 2>&1"');
            Sys.exit(0);
        } catch (e) {
            throwError(new Exception(
                'Mod extraction failed! ' + e.message +
                (FileSystem.exists(logPath) ? ' You can find the extraction log at: $logPath' : '')
            ));
        }
    }

    function createTempDir(prefix:String = 'dhx_download_'):String {
        var baseTemp = Sys.getEnv('TEMP');
        if (baseTemp == null) baseTemp = Sys.getEnv('TMP');
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

    public static function formatBytes(bytes:Int64):String {
        if (bytes < 1024)
            return bytes + ' Bytes';

        var bytesFloat:Float = Std.parseFloat(Int64.toStr(bytes));

        if (bytesFloat < 1024.0 * 1024.0)
            return (Math.ffloor((bytesFloat / 1024.0) * 100) / 100) + ' KB';
        else if (bytesFloat < 1024.0 * 1024.0 * 1024.0)
            return (Math.ffloor((bytesFloat / (1024.0 * 1024.0)) * 100) / 100) + ' MB';
        else
            return (Math.ffloor((bytesFloat / (1024.0 * 1024.0 * 1024.0)) * 100) / 100) + ' GB';
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
        if (text == null || text == '') return '';

        var measurer = new TextField();
        var format = new TextFormat(null, cast fontSize * 1.2);
        measurer.defaultTextFormat = format;
        measurer.text = text;

        if (measurer.textWidth <= maxWidth)
            return text;

        var truncated = text;
        while (measurer.textWidth > maxWidth && truncated.length > 0) {
            truncated = truncated.substr(0, truncated.length - 1);
            measurer.text = truncated + '...';
        }

        return measurer.text;
    }

    function onEnterFrame(e:Event) {
        if (hasPendingUpdate) {
            hasPendingUpdate = false;
            if (progress != null && pendingTotal > 0) {
                var pctInt64:Int64 = (pendingCur * 100) / pendingTotal;
                var pct:Float = Std.parseFloat(Int64.toStr(pctInt64));
                if (pct >= 0 && pct <= 100) {
                    progress.pos = pct;
                }
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