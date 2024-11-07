part of '../playerfeature.dart';

class ReservedSongItem {
  final String thumbnailURL;
  final String title;
  final String artist;
  final String reservedBy;
  final bool isPlaying;

  ReservedSongItem({
    required this.thumbnailURL,
    required this.title,
    required this.artist,
    required this.reservedBy,
    required this.isPlaying,
  });
}
