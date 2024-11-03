part of '../downloadfeature.dart';

class IdentifiedSongDetails {
  final String id;
  final String source;
  final String imageUrl;
  final String songTitle;
  final String songArtist;
  final String songLanguage;
  final bool isOffVocal;
  final bool videoHasLyrics;
  final String songLyrics;
  final bool alreadyExists;

  IdentifiedSongDetails({
    required this.id,
    required this.source,
    required this.imageUrl,
    required this.songTitle,
    required this.songArtist,
    required this.songLanguage,
    required this.isOffVocal,
    required this.videoHasLyrics,
    required this.songLyrics,
    required this.alreadyExists,
  });

  IdentifiedSongDetails copyWith({
    String? id,
    String? source,
    String? imageUrl,
    String? songTitle,
    String? songArtist,
    String? songLanguage,
    bool? isOffVocal,
    bool? videoHasLyrics,
    String? songLyrics,
    bool? alreadyExists,
  }) =>
      IdentifiedSongDetails(
        id: id ?? this.id,
        source: source ?? this.source,
        imageUrl: imageUrl ?? this.imageUrl,
        songTitle: songTitle ?? this.songTitle,
        songArtist: songArtist ?? this.songArtist,
        songLanguage: songLanguage ?? this.songLanguage,
        isOffVocal: isOffVocal ?? this.isOffVocal,
        videoHasLyrics: videoHasLyrics ?? this.videoHasLyrics,
        songLyrics: songLyrics ?? this.songLyrics,
        alreadyExists: alreadyExists ?? this.alreadyExists,
      );
}
