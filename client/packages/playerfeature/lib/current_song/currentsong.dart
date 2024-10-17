part of '../playerfeature.dart';

class CurrentSong {
  final String id;
  final String title;
  final String artist;
  final String thumbnailURL;
  final String videoURL;
  final String reservingUser; //TODO: This will be an actual user object

  CurrentSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailURL,
    required this.videoURL,
    required this.reservingUser,
  });
}
