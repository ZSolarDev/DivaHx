package backend.utils;

import openfl.Lib;
import sys.FileSystem;

using StringTools;

class Validate {
    @:noCompletion static var mmPathValid:Bool = false;
    public static function isValidMMPath():Bool
        return mmPathValid;

    public static function invalidateMMPath() {
        mmPathValid = false;
    }
    public static function validateMMPath() {
        mmPathValid = true;
    }
    public static function checkInstallation(path:String):{isValid:Bool, details:String} {
        if (!mmPathValid) {
            return validateInstallation(path);
        } else
            return {isValid: true, details: ''};
    }

    static var requiredFiles:Map<String, Bool> = [
        'DivaMegaMix.exe' => false,
        'diva_main.cpk' => false,
        'diva_main_region.cpk' => false
    ];

    static var dmlFiles:Map<String, Bool> = [
        'config.toml' => false,
        'dinput8.dll' => false
    ];

    static var minimumSizes:Map<String, Float> = [
        'diva_main_region.cpk' => 550000,
        'DivaMegaMix.exe' => 300000
        // Don't check diva_main, it fails.
    ];

    public static function validateInstallation(path:String):{isValid:Bool, details:String} {
        trace('Validating installation.');
        if (path == null || path.trim() == '') {
            trace("Welp. Uh, I guess we're not validating any installation cause it's empty.");
            return {isValid: false, details: 'The input path is empty.'};
        }
        var exists = FileSystem.exists(path);
        if (exists) {
            trace('Validation Update || The path exists.');
            var isDir = FileSystem.isDirectory(path);
            if (isDir) {
                trace('Validation Update || The path is a directory.');
                var files = FileSystem.readDirectory(path);
                if (files.length > 0) {
                    trace('Validation Update || The path contains files.');
                    var mmCheck = hasMM(files, path);
                    if (mmCheck.isValid) {
                        trace('Validation Update || The path contains a valid installation.');
                        var isModded = checkModded(files);
                        if (isModded.isValid) {
                            trace('Validation Update || The path contains a valid modded installation.');
                            trace('Validation success.');
                            validateMMPath(); 
                        } else trace('Validation failed. The path:\n$path\nis not detected as a valid modded installation.');
                        return isModded;
                    } else {
                        trace('Validation failed. The path:\n$path\nis not detected as a valid installation.');
                        return mmCheck;
                    }
                } else {
                    trace('Validation failed. The path:\n$path\nis empty.');
                    return {isValid: false, details: 'The path @@$path@@ is empty.'};
                }
            } else {
                trace('Validation failed. The path:\n$path\nis not a directory.');
                return {isValid: false, details: 'The path @@$path@@ is not a directory.'};
            }
        }

        trace('Validation failed. The path:\n$path\ndoes not exist.');
        return {isValid: false, details: 'Could not find a %%Hatsune Miku: Project DIVA Mega Mix+%% installation at path: \n@@$path@@'};
    }

    static function checkModded(files:Array<String>):{isValid:Bool, details:String} {
        var isModded = true;
        var nonexistant:Array<String> = [];

        // Note the existence of any dml files detected
        for (file in files) {
            if (dmlFiles.exists(file))
                dmlFiles.set(file, true);
        }

        // Check for nonexistant dml files
        for (mod in dmlFiles.keys()) {
            if (!dmlFiles.get(mod)) {
                isModded = false;
                nonexistant.push(mod);
            }
        }

        for (mod in dmlFiles.keys())
            dmlFiles.set(mod, false);

        // Build error message if needed
        var error = '';
        if (!isModded) 
            error = 'Your %%Hatsune Miku: Project DIVA Mega Mix+%% installation is missing the following files required by %%Diva Mod Loader%% :\n\n@@${nonexistant.join('\n')}@@\n\nEnsure %%Diva Mod Loader%% is installed! Download it ##here##.';
        
        return {isValid: isModded, details: error};
    }

    static function hasMM(files:Array<String>, path:String):{isValid:Bool, details:String} {
        var valid = true;
        var nonexistant:Array<String> = [];
        var corrupt:Array<String> = [];

        // Note the existence of any required files detected
        for (file in files) {
            if (requiredFiles.exists(file))
                requiredFiles.set(file, true);
        }

        // Check for nonexistant required files
        for (req in requiredFiles.keys()) {
            if (!requiredFiles.get(req)) {
                valid = false;
                nonexistant.push(req);
            } else if (minimumSizes.exists(req)) {
                // Check file size against minimum threshold (bytes to kb)
                var filePath = path + '\\' + req;
                var size = Std.int(FileSystem.stat(filePath).size / 1024);
                if (size < minimumSizes.get(req)) {
                    valid = false;
                    corrupt.push(req);
                }
            }
        }

        for (req in requiredFiles.keys())
            requiredFiles.set(req, false);
        
        // Build error message if needed
        var error = '';
        if (nonexistant.length > 0)
            error += 'Your %%Hatsune Miku: Project DIVA Mega Mix+%% installation is missing the following files:\n\n@@${nonexistant.join('\n')}@@\n\nIs this the right path to the installation? @@$path@@';
        if (corrupt.length > 0) {
            if (error.length > 0) error += '\n\n';
            error += 'The following files appear to be corrupted:\n\n@@${corrupt.join('\n')}@@\n\nTry verifying your game files through Steam.';
        }
        
        return {isValid: valid, details: error};
    }
}