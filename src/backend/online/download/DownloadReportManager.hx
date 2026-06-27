package backend.online.download;

import backend.online.gamebanana.GBModData;
import backend.online.gamebanana.GBMod;
import backend.online.dma.DMAMod;
import hxFileManager.FileManager;
import components.dialogs.DMAModDownloadDialog;
import components.dialogs.GBModDownloadDialog;
import components.dialogs.ScrollDialog;
import sys.io.File;
import haxe.Json;
import sys.FileSystem;
import backend.utils.Update;

using StringTools;

class DownloadReportManager {
    static var reports:Map<String, DownloadReport> = [];
    public static function getReports():Map<String, DownloadReport> return reports;

    public static function init() {
        Update.registerNonC(updateReports);
    }

    public static function dispose() {
        Update.unregisterNonC(updateReports);
    }

    static function updateReports(dt:Float)
    {
        manageReportRegistration();
        manageReports();
        manageErrorReport();
    }

    static function manageErrorReport() {
        if (FileSystem.exists('MREPORT')) {
            try {
                var data:FailedDownloadReport = Json.parse(File.getContent('MREPORT'));
                var dialog:ScrollDialog = null;
                
                if (data.modType == 'dma' || data.modType == '')
                    dialog = new DMAModDownloadDialog(data.title, '### ${data.title}\n${data.data}', true, ((data.mod == null) ? null : (data.mod:DMAMod)));
                else if (data.modType == 'gb')
                    dialog = new GBModDownloadDialog(data.title, '### ${data.title}\n${data.data}', true, (data.mod:GBMod), (data.modData:GBModData));
                

                if (dialog != null) {
                    trace('Mod download report: ${data.title}');
                    dialog.showDialog();
                }
                FileSystem.deleteFile('MREPORT');
            } catch (e) {
                var dialog:ScrollDialog = new ScrollDialog('Failed to display a mod download report!', '### Failed to display a mod download report!\nError: ${e.message}\nStack:${e.stack.toString()}', true);
                dialog.showDialog();

                FileSystem.deleteFile('MREPORT');
            }
        }
    }

    static function manageReportRegistration() {
        for (file in FileSystem.readDirectory('./')) {
            if (file.startsWith('MREPORT(') && reports.get(file) == null) {
                var content = File.getContent(file);
                var report:DownloadReport = {};
                for (lineID in 0...content.split('\n').length) {
                    var line = content.split('\n')[lineID];
                    if (lineID > 0)
                        report.extractionLog += '\n$line';
                    else
                        report = Json.parse(line);
                }
                
                var modName = report.modType == 'gb' ? report.mod._sName : report.mod.name;
                trace('Registered new mod download report: $modName');
                
                reports.set(file, report);
            }
        }
    }

    static function manageReports() {
        for (reportName in reports.keys()) {
            var report:DownloadReport = reports.get(reportName);
            try {
                if (FileSystem.exists(reportName)) {
                    var content = File.getContent(reportName);
                    report.extractionLog = '';
                    for (lineID in 0...content.split('\n').length) {
                        var line = content.split('\n')[lineID];
                        if (lineID > 7)
                            report.extractionLog += '\n$line';
                    }
                    var complete = false;
                    var dialog:ScrollDialog = null;
                    
                    var modName = report.modType == 'gb' ? report.mod._sName : report.mod.name;

                    if (report.extractionLog.contains('ERROR: ')) {
                        if (report.modType == 'dma' || report.modType == '')
                            dialog = new DMAModDownloadDialog('Failed to extract mod "$modName"!', '### Failed to extract mod "$modName"!\n7-Zip log:\n${report.extractionLog}', true, (report.mod:DMAMod));
                        else if (report.modType == 'gb')
                            dialog = new GBModDownloadDialog('Failed to extract mod "$modName"!', '### Failed to extract mod "$modName"!\n7-Zip log:\n${report.extractionLog}', true, (report.mod:GBMod), (report.modData:GBModData));
                        
                        
                        trace('Mod download report: Failed to extract mod "$modName"!');
                        complete = true;
                    } else if (report.extractionLog.contains('Everything is Ok')) {
                        var fileName = 'Unknown File'; 

                        if (report.modType == 'gb' && report.modData != null) {
                            var gbFileKeys = Reflect.fields(report.modData.filesAFiles);
                            
                            if (report.fileIdx >= 0 && report.fileIdx < gbFileKeys.length) {
                                var fileInfo:Dynamic = Reflect.field(report.modData.filesAFiles, gbFileKeys[report.fileIdx]);
                                if (fileInfo != null && fileInfo._sFile != null)
                                    fileName = fileInfo._sFile;
                            }
                        } else if (report.modType == 'dma' || report.modType == '')
                            fileName = report.mod.file_names[report.fileIdx];
                        
                        if (report.modType == 'dma' || report.modType == '')
                            dialog = new DMAModDownloadDialog('Successfully downloaded mod "$modName"!', '##### Successfully downloaded mod "$modName"!\nThe file "$fileName" has been installed as a mod.', false, (report.mod:DMAMod));
                        else if (report.modType == 'gb')
                            dialog = new GBModDownloadDialog('Successfully downloaded mod "$modName"!', '##### Successfully downloaded mod "$modName"!\n"$fileName" has been installed as a mod.', false, (report.mod:GBMod), (report.modData:GBModData));
                        
                        
                        trace('Mod download report: Successfully downloaded mod "$modName"!');
                        complete = true;
                    }
                    
                    if (complete) {
                        if (dialog != null)
                            dialog.showDialog();
                        haxe.Timer.delay(() -> {
                            if (FileSystem.exists(report.archiveFolder))
                            @:privateAccess FileManager.removePath(report.archiveFolder);
                        }, 1000);
                        trace('Unregistered mod download report: $modName');
                        reports.remove(reportName);
                        FileSystem.deleteFile(reportName);
                    }
                } else {
                    var modName = report.modType == 'gb' ? report.mod._sName : report.mod.name;
                    trace('Unregistered leftover mod download report: $modName');
                    reports.remove(reportName);
                }
            } catch (e) {
                trace('Error updating report $reportName\nError: ${e.message}\nStack:${e.stack.toString()}');
                continue;
            }
        }
    }
}