part of '../downloadfeature.dart';

class DownloadableItem {
  final String sourceUrl;
  final String title;
  final String artist;
  final String thumbnailURL;
  final String duration;

  DownloadableItem({
    required this.sourceUrl,
    required this.title,
    required this.artist,
    required this.thumbnailURL,
    required this.duration,
  });
}

// Replace with your method to get songs
List<DownloadableItem> getSongs() {
  return [
    DownloadableItem(
      sourceUrl: 'https://example.com/song1.mp3',
      title: 'Song 1',
      artist: 'Artist 1',
      thumbnailURL: 'https://example.com/thumbnail1.jpg',
      duration: '3:45',
    ),
    DownloadableItem(
      sourceUrl: 'https://example.com/song2.mp3',
      title: 'Song 2',
      artist: 'Artist 2',
      thumbnailURL: 'https://example.com/thumbnail2.jpg',
      duration: '4:20',
    ),
    // Add more songs here
  ];
}
