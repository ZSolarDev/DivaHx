package backend.online.dma;

import haxe.Int64;

/* 
    I didn't include the "private" field because:
    1. It conflicts with the keyword
    2. There will never be a private mod on the fetched public mod list
*/
typedef DMAMod = {
    var id:Int;
    var name:String;
    var text:String;
    var images:Array<String>;
    var files:Array<String>;
    var time:String;
    var post_type:String;
    var download_count:Int;
    var like_count:Int;
    var authors:Array<DMAModAuthor>;
    var dependencies:Array<DMAMod>;
    var dependency_descriptions:Array<Dynamic>;
    var file_names:Array<String>;
    var file_sizes:Array<Int64>;
    var explicit:Bool;
    var explicit_reason:String;
}