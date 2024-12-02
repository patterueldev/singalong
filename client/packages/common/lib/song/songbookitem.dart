part of '../common.dart';

class SongbookItem {
  final String id;
  final String title;
  final String artist;
  final String thumbnailURL;
  final bool
      alreadyPlayed; // doesn't mean it can't be played again, just for indication

  const SongbookItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailURL,
    required this.alreadyPlayed,
  });
}
