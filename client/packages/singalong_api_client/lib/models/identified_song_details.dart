part of '../singalong_api_client.dart';

@JsonSerializable()
class APIIdentifiedSongDetails {
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

  APIIdentifiedSongDetails({
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

  factory APIIdentifiedSongDetails.fromJson(Map<String, dynamic> json) =>
      _$APIIdentifiedSongDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$APIIdentifiedSongDetailsToJson(this);
  factory APIIdentifiedSongDetails.fromResponse(Response response) {
    return APIIdentifiedSongDetails.fromJson(json.decode(response.body));
  }

  @override
  String toString() {
    return 'APIIdentifiedSongDetails(id: $id, source: $source, imageUrl: $imageUrl, songTitle: $songTitle, songArtist: $songArtist, songLanguage: $songLanguage, isOffVocal: $isOffVocal, videoHasLyrics: $videoHasLyrics, songLyrics: $songLyrics, lengthSeconds: $lengthSeconds, metadata: $metadata, alreadyExists: $alreadyExists)';
  }
}

@JsonSerializable()
class APIIdentifySongParameters {
  final String url;

  APIIdentifySongParameters({
    required this.url,
  });

  factory APIIdentifySongParameters.fromJson(Map<String, dynamic> json) =>
      _$APIIdentifySongParametersFromJson(json);
  Map<String, dynamic> toJson() => _$APIIdentifySongParametersToJson(this);
}
/*

data class IdentifiedSong(
    val id: String,
    val source: String,
    val imageUrl: String,
    val songTitle: String,
    val songArtist: String,
    val songLanguage: String,
    val isOffVocal: Boolean,
    val videoHasLyrics: Boolean,
    val songLyrics: String,
    val lengthSeconds: Int,
    val metadata: Map<String, Any>?,
    val alreadyExists: Boolean = false,
)

 */
