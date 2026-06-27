package backend.online.gamebanana;

enum abstract GBCategory(String) from String to String {
    var None = '';
    var Covers = '17311:Covers';
    var CustomSongs = '17345:Custom Songs';
    var Customization = '17315:Customization';
    var Patches = '17530:Patches';
    var RestorationsAndFixes = '22002:Restorations & Fixes';
    var UI = '17306:User Interface';
}