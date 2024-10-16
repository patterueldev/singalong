part of '../sessionfeature.dart';

class ReservedSongItem {
  final String id;
  final String songId;
  final String title;
  final String artist;
  final String imageURL;
  final String reservingUser;
  final bool currentPlaying;

  const ReservedSongItem({
    required this.id,
    required this.songId,
    required this.title,
    required this.artist,
    required this.imageURL,
    required this.reservingUser,
    required this.currentPlaying,
  });
}
