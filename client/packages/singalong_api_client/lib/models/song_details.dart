part of '../singalong_api_client.dart';

@JsonSerializable()
class APISongDetails {
  final String id;
  final String source;
  final String title;
  final String artist;
  final String language;
  final bool isOffVocal;
  final bool videoHasLyrics;
  final int duration;
  final List<String> genres;
  final List<String> tags;
  final Map<String, String> metadata;
  final String thumbnailPath;
  final bool wasReserved;
  final bool currentPlaying;
  final String? lyrics;
  final String addedBy;
  final String addedAtSession;
  final String lastUpdatedBy;
  final bool isCorrupted;

  APISongDetails({
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
    required this.thumbnailPath,
    required this.wasReserved,
    required this.currentPlaying,
    this.lyrics,
    required this.addedBy,
    required this.addedAtSession,
    required this.lastUpdatedBy,
    required this.isCorrupted,
  });

  factory APISongDetails.fromJson(Map<String, dynamic> json) =>
      _$APISongDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$APISongDetailsToJson(this);
}

@JsonSerializable()
class APILoadSongDetailsParameters {
  final String songId;
  final String? roomId;

  APILoadSongDetailsParameters({
    required this.songId,
    this.roomId,
  });

  factory APILoadSongDetailsParameters.fromJson(Map<String, dynamic> json) =>
      _$APILoadSongDetailsParametersFromJson(json);

  Map<String, dynamic> toJson() => _$APILoadSongDetailsParametersToJson(this);

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
