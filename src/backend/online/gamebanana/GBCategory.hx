package backend.online.gamebanana;

enum abstract GBCategory(String) from String to String {
    var None = '';
    var Covers = '17311:Covers';
    var CustomSongs = '17345:Custom Songs';
    var CustomSongsEXEX = '25910:Additional Difficulties';
    var Customization = '17315:Customization';
    var Modules = '17293:Modules';
    var Accessories = '17295:Accessories';
    var Reskins = '21999:Skins';
    var Other = '17288:Other';
    var Patches = '17530:Patches';
    var RestorationsAndFixes = '22002:Restorations & Fixes';
    var SoundReplacements = '22001:Sound Replacements';
    var Translations = '22000:Translations';
    var UI = '17306:User Interface';
}