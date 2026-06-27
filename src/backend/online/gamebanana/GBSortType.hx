package backend.online.gamebanana;

enum abstract GBSortType(String) from String to String {
    var Newest = 'Generic_Newest';
    var Oldest = 'Generic_Oldest';
    var LatestModified = 'Generic_LatestModified';
    var NewAndUpdated = 'Generic_NewAndUpdated';
    var LatestUpdated = 'Generic_LatestUpdated';
    var MostLiked = 'Generic_MostLiked';
    var MostCommented = 'Generic_MostCommented';
    var LatestComment = 'Generic_LatestComment';
    var MostDownloaded = 'Generic_MostDownloaded';
}