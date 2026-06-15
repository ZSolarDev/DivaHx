package backend.online.dma;

enum abstract DMAPostType(String) from String to String {
    var Song = 'Song';
    var Cover = 'Cover';
    var Module = 'Module';
    var UI = 'UI';
    var Plugin = 'Plugin';
    var Other = 'Other';
}