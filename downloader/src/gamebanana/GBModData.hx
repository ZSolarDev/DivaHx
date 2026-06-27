package gamebanana;

abstract GBModData(Array<Dynamic>) from Array<Dynamic> to Array<Dynamic> {
    public inline function new(a:Array<Dynamic>) this = a;

    public var text(get, never):String;
    inline function get_text():String return this[0];

    public var downloads(get, never):Int;
    inline function get_downloads():Int return this[1];

    public var filesAFiles(get, never):Dynamic;
    inline function get_filesAFiles():Dynamic return this[2];

    public var likes(get, never):Int;
    inline function get_likes():Int return this[3];

    public var nsfwBIsNsfw(get, never):Bool;
    inline function get_nsfwBIsNsfw():Bool return this[4];

    public var description(get, never):String;
    inline function get_description():String return this[5];
}