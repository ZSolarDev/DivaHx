package backend.utils;

import haxe.Json;
import sys.FileSystem;
import sys.io.File;

class Config {
    public static var data:ConfigData = { 
        mmPath: ''
    };

    public static function bind() {
        var hasConfig = FileSystem.exists('./config.mms');
        if (hasConfig) {
            data = Json.parse(File.getContent('./config.mms'));
        } else
            flush();
    }

    public static function flush() {
        File.saveContent('./config.mms', Json.stringify(data, null, '   '));
    }
}

typedef ConfigData = {
    var mmPath:String;
}