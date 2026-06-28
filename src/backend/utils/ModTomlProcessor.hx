package backend.utils;

using StringTools;

class ModTomlProcessor {
    static var KEYS_TO_REMOVE = [
        'enabled', 'include', 'dll', 'name', 'description', 'version', 'date', 'author'
    ];

    public static function stripMetadataLines(tomlContent:String):{res:String, metadata:Array<String>} {
        var lines = tomlContent.split('\n');
        var result = [];
        var metadata = [];

        for (line in lines) {
            var trimmed = StringTools.ltrim(line);
            var shouldRemove = false;

            for (key in KEYS_TO_REMOVE) {
                if (trimmed.indexOf(key + ' =') == 0 || trimmed.indexOf(key + '=') == 0) {
                    shouldRemove = true;
                    break;
                }
            }

            if (shouldRemove) {
                metadata.push(line);
            } else {
                result.push(line);
            }
        }

        return {res: result.join('\n').trim(), metadata: metadata};
    }

    public static function getModStringFromToml(tomlContent:String, key:String):String {
        var regex = new EReg("^\\s*" + key + "\\s*=\\s*\"([^\"]*)\"\\s*$", "m");
        if (regex.match(tomlContent)) 
            return regex.matched(1);
        return '';
    }

    public static function hasNonCommentLine(tomlContent:String):Bool {
        for (line in tomlContent.split('\n')) {
            var trimmed = StringTools.trim(line);
            if (trimmed != '' && trimmed.charAt(0) != '#') {
                return true;
            }
        }
        return false;
    }

    public static function buildModInfoString(tomlContent:String):String {
        var fields = [
            {key: 'name', label: 'Name'},
            {key: 'description', label: 'Description'},
            {key: 'version', label: 'Version'},
            {key: 'date', label: 'Date'},
            {key: 'author', label: 'Author'}
        ];

        var lines = [];

        for (field in fields) {
            var value = ModTomlProcessor.getModStringFromToml(tomlContent, field.key);
            if (value != '') {
                lines.push('${field.label}: $value');
            }
        }

        return lines.join('\n');
    }
}