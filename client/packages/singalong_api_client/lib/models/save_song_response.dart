part of '../singalong_api_client.dart';

@JsonSerializable()
class APISaveSongResponseData {
  final String id;
  final String source;
  final String sourceId;
  final String thumbnailPath;
  final String videoPath;
  final String songTitle;
  final String songArtist;
  final String songLanguage;
  final bool isOffVocal;
  final bool videoHasLyrics;
  final String songLyrics;
  final int lengthSeconds;

  APISaveSongResponseData({
    required this.id,
    required this.source,
    required this.sourceId,
    required this.thumbnailPath,
    required this.videoPath,
    required this.songTitle,
    required this.songArtist,
    required this.songLanguage,
    required this.isOffVocal,
    required this.videoHasLyrics,
    required this.songLyrics,
    required this.lengthSeconds,
  });

  factory APISaveSongResponseData.fromJson(Map<String, dynamic> json) =>
      _$APISaveSongResponseDataFromJson(json);

  Map<String, dynamic> toJson() => _$APISaveSongResponseDataToJson(this);
}
