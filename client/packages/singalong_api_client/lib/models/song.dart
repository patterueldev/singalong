part of '../singalong_api_client.dart';

@JsonSerializable()
class APIPaginatedSongs {
  final List<APISongItem> items;
  final int? nextOffset;
  final String? nextCursor;
  final int? nextPage;

  APIPaginatedSongs({
    required this.items,
    this.nextOffset,
    this.nextCursor,
    this.nextPage,
  });

  factory APIPaginatedSongs.fromJson(Map<String, dynamic> json) =>
      _$APIPaginatedSongsFromJson(json);
  Map<String, dynamic> toJson() => _$APIPaginatedSongsToJson(this);
}

@JsonSerializable()
class APISongItem {
  final String id;
  final String thumbnailPath;
  final String title;
  final String artist;
  final String language;
  final bool isOffVocal;
  final int lengthSeconds;

  APISongItem({
    required this.id,
    required this.thumbnailPath,
    required this.title,
    required this.artist,
    required this.language,
    required this.isOffVocal,
    required this.lengthSeconds,
  });

  factory APISongItem.fromJson(Map<String, dynamic> json) =>
      _$APISongItemFromJson(json);
  Map<String, dynamic> toJson() => _$APISongItemToJson(this);
}

@JsonSerializable()
class APILoadSongsParameters {
  final String? keyword;
  final int? limit;
  final int? nextOffset;
  final String? nextCursor;
  final int? nextPage;
  final String? roomId;

  APILoadSongsParameters({
    this.keyword,
    this.limit,
    this.nextOffset,
    this.nextCursor,
    this.nextPage,
    this.roomId,
  });

  factory APILoadSongsParameters.fromJson(Map<String, dynamic> json) =>
      _$APILoadSongsParametersFromJson(json);
  Map<String, dynamic> toJson() => _$APILoadSongsParametersToJson(this);
}

@JsonSerializable()
class APIReserveSongParameters {
  final String songId;

  APIReserveSongParameters({
    required this.songId,
  });

  factory APIReserveSongParameters.fromJson(Map<String, dynamic> json) =>
      _$APIReserveSongParametersFromJson(json);
  Map<String, dynamic> toJson() => _$APIReserveSongParametersToJson(this);
}

/*
{
    "songId": "67092f560e02e456cb54813c"
}
 */
