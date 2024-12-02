part of '../downloadfeature.dart';

class DownloadableItem {
  final String sourceUrl;
  final String title;
  final String artist;
  final String thumbnailURL;
  final String duration;
  final bool alreadyDownloaded;

  DownloadableItem({
    required this.sourceUrl,
    required this.title,
    required this.artist,
    required this.thumbnailURL,
    required this.duration,
    required this.alreadyDownloaded,
  });
}
