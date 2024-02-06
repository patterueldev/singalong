part of '../../reservations_feature.dart';

abstract class Song {
  final String title;
  final String artist;
  final String album;
  final String? imageUrl;

  Song({
    required this.title,
    required this.artist,
    required this.album,
    this.imageUrl,
  });
}

class DefaultSong implements Song {
  @override
  final String title;
  @override
  final String artist;
  @override
  final String album;
  @override
  final String? imageUrl;

  DefaultSong({
    required this.title,
    required this.artist,
    required this.album,
    this.imageUrl,
  });
}
