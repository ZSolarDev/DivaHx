package backend.utils;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;

class Config {
    public static var data:ConfigData = { 
        mmPath: ''
    }

    public static function bind() {
        var hasConfig = FileSystem.exists('./config.dhxc');
        if (hasConfig) {
            data = Json.parse(File.getContent('./config.dhxc'));
        } else {
            var possiblePath = '${Sys.getCwd().charAt(0)}:/Program Files (x86)/Steam/steamapps/common/Hatsune Miku Project DIVA Mega Mix Plus';
            if (FileSystem.exists(possiblePath))
                data.mmPath = possiblePath;
            flush();
        }
    }

    public static function flush() {
        File.saveContent('./config.dhxc', Json.stringify(data, null, '   '));
    }
}

typedef ConfigData = {
    var mmPath:String;
}