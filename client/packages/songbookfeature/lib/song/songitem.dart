part of '../songbookfeature.dart';

class SongItem {
  final String id;
  final String title;
  final String artist;
  final String thumbnailURL;
  final bool
      alreadyPlayed; // doesn't mean it can't be played again, just for indication

  const SongItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailURL,
    required this.alreadyPlayed,
  });
}
