part of '../common.dart';

class CurrentSong {
  final String id;
  final String title;
  final String artist;
  final String thumbnailURL;
  final String videoURL;
  final int durationInSeconds;
  final String lyrics;
  final String reservingUser;
  final double volume;

  CurrentSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailURL,
    required this.videoURL,
    required this.durationInSeconds,
    required this.lyrics,
    required this.reservingUser,
    required this.volume,
  });
}
