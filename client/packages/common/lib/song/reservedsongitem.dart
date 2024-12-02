part of '../common.dart';

class ReservedSongItem {
  final String id;
  final String songId;
  final String title;
  final String artist;
  final String thumbnailURL;
  final String reservingUser;
  final bool currentPlaying;
  final bool finishedPlaying;

  ReservedSongItem({
    required this.id,
    required this.songId,
    required this.title,
    required this.artist,
    required this.thumbnailURL,
    required this.reservingUser,
    required this.currentPlaying,
    required this.finishedPlaying,
  });
}
