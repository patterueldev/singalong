part of '../singalong_api_client.dart';

@JsonSerializable()
class APIUpdateSongParameters {
  final String songId;
  final String title;
  final String artist;
  final String language;
  final bool isOffVocal;
  final bool videoHasLyrics;
  final String songLyrics;
  final Map<String, String> metadata;
  final List<String> genres;
  final List<String> tags;

  APIUpdateSongParameters({
    required this.songId,
    required this.title,
    required this.artist,
    required this.language,
    required this.isOffVocal,
    required this.videoHasLyrics,
    required this.songLyrics,
    required this.metadata,
    required this.genres,
    required this.tags,
  });

  factory APIUpdateSongParameters.fromJson(Map<String, dynamic> json) =>
      _$APIUpdateSongParametersFromJson(json);

  Map<String, dynamic> toJson() => _$APIUpdateSongParametersToJson(this);
}

/*

data class UpdateSongParameters (
    val songId: String,
    val title: String,
    val artist: String,
    val language: String,
    val isOffVocal: Boolean,
    val videoHasLyrics: Boolean,
    val songLyrics: String,
    val metadata: Map<String, String>,
    val genres: List<String>,
    val tags: List<String>,
)
 */
