package backend.online.dma;

enum abstract DMASortType(String) from String to String {
    var Newest = 'time:desc';
    var Oldest = 'time:asc';
    var MostDownloaded = 'download_count:desc';
    var MostLiked = 'like_count:desc';
    var LeastDownloaded = 'download_count:asc';
    var LeastLiked = 'like_count:asc';
}