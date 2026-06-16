package backend.utils;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;
import lime.app.Application;

class SingleInstance {
    private static var lockPath:String;
    private static var activeStream:FileOutput;

    public static function check():Bool {
        var lockDir = Sys.getEnv("TEMP");
        if (lockDir == null || lockDir == "") lockDir = Sys.getEnv("TMPDIR");
        if (lockDir == null || lockDir == "") lockDir = "./";

        lockPath = Path.join([lockDir, "DivaHX_boot.lock"]);

        // 1. If it doesn't exist at all, we are the first instance
        if (!FileSystem.exists(lockPath))
            return claimLock();

        // 2. If it does exist, test if the first instance is actually alive or if it's a ghost file from a crash
        // We a command to try and append to it.
        // If the first instance is alive, the OS blocks the system command and returns an error code (!= 0)
        var sysCheckCode = 1;
        try {
            sysCheckCode = Sys.command('echo test >> "${lockPath}"');
        } catch(e:Dynamic) {
            sysCheckCode = 0; // Fallback if system shell execution fails
        }

        // If the command returned 0, the file was unlocked/unprotected (the first instance is dead)
        if (sysCheckCode == 0) {
            try { FileSystem.deleteFile(lockPath); } catch(e:Dynamic) {}
            return claimLock();
        }

        // Otherwise, the first instance is alive
        return false;
    }

    private static function claimLock():Bool {
        try {
            File.saveContent(lockPath, "DivaHX Running");
            
            activeStream = File.append(lockPath, false);

            Application.current.onExit.add(function(exitCode) {
                try {
                    if (activeStream != null) {
                        activeStream.close();
                        if (FileSystem.exists(lockPath)) {
                            FileSystem.deleteFile(lockPath);
                        }
                    }
                } catch(e:Dynamic) {}
            });

            return true;
        } catch(e:Dynamic) {
            return false;
        }
    }
}