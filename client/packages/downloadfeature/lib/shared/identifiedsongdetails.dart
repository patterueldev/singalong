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
  final int lengthSeconds;
  final Map<String, dynamic>? metadata;
  final List<String> genres;
  final List<String> tags;
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
    required this.lengthSeconds,
    required this.metadata,
    required this.genres,
    required this.tags,
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
    int? lengthSeconds,
    Map<String, dynamic>? metadata,
    List<String>? genres,
    List<String>? tags,
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
        lengthSeconds: lengthSeconds ?? this.lengthSeconds,
        metadata: metadata ?? this.metadata,
        genres: genres ?? this.genres,
        tags: tags ?? this.tags,
        alreadyExists: alreadyExists ?? this.alreadyExists,
      );

  @override
  String toString() {
    return 'IdentifiedSongDetails(id: $id, source: $source, imageUrl: $imageUrl, songTitle: $songTitle, songArtist: $songArtist, songLanguage: $songLanguage, isOffVocal: $isOffVocal, videoHasLyrics: $videoHasLyrics, songLyrics: $songLyrics, lengthSeconds: $lengthSeconds, metadata: $metadata, genres: $genres, tags: $tags, alreadyExists: $alreadyExists)';
  }
}
