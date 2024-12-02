part of '../common.dart';

class SongDetails {
  final String id;
  final String source;
  String title;
  String artist;
  String language;
  bool isOffVocal;
  bool videoHasLyrics;
  final int duration;
  List<String> genres;
  List<String> tags;
  Map<String, String> metadata;
  final String thumbnailURL;
  final bool currentPlaying;
  String? lyrics;
  final String addedBy;
  final String addedAtSession;
  final String lastUpdatedBy;
  final bool isCorrupted;

  SongDetails({
    required this.id,
    required this.source,
    required this.title,
    required this.artist,
    required this.language,
    required this.isOffVocal,
    required this.videoHasLyrics,
    required this.duration,
    required this.genres,
    required this.tags,
    required this.metadata,
    required this.thumbnailURL,
    required this.currentPlaying,
    this.lyrics,
    required this.addedBy,
    required this.addedAtSession,
    required this.lastUpdatedBy,
    required this.isCorrupted,
  });

  SongDetails copyWith({
    String? id,
    String? source,
    String? title,
    String? artist,
    String? language,
    bool? isOffVocal,
    bool? videoHasLyrics,
    int? duration,
    List<String>? genres,
    List<String>? tags,
    Map<String, String>? metadata,
    String? thumbnailURL,
    bool? currentPlaying,
    String? lyrics,
    String? addedBy,
    String? addedAtSession,
    String? lastUpdatedBy,
    bool? isCorrupted,
  }) {
    return SongDetails(
      id: id ?? this.id,
      source: source ?? this.source,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      language: language ?? this.language,
      isOffVocal: isOffVocal ?? this.isOffVocal,
      videoHasLyrics: videoHasLyrics ?? this.videoHasLyrics,
      duration: duration ?? this.duration,
      genres: genres ?? this.genres,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      thumbnailURL: thumbnailURL ?? this.thumbnailURL,
      currentPlaying: currentPlaying ?? this.currentPlaying,
      lyrics: lyrics ?? this.lyrics,
      addedBy: addedBy ?? this.addedBy,
      addedAtSession: addedAtSession ?? this.addedAtSession,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      isCorrupted: isCorrupted ?? this.isCorrupted,
    );
  }

  @override
  String toString() {
    return 'SongDetails(id: $id, source: $source, title: $title, artist: $artist, language: $language, isOffVocal: $isOffVocal, videoHasLyrics: $videoHasLyrics, duration: $duration, genres: $genres, tags: $tags, metadata: $metadata, thumbnailURL: $thumbnailURL, currentPlaying: $currentPlaying, lyrics: $lyrics, addedBy: $addedBy, addedAtSession: $addedAtSession, lastUpdatedBy: $lastUpdatedBy)';
  }
}
