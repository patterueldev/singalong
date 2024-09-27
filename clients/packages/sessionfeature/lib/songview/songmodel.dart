part of '../sessionfeature.dart';

class SongModel {
  final String title;
  final String artist;
  final String imageURL;
  final bool currentPlaying;
  final String? lyrics;

  SongModel({
    required this.title,
    required this.artist,
    required this.imageURL,
    required this.currentPlaying,
    this.lyrics,
  });
}
