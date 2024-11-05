part of '../singalong_api_client.dart';

@JsonSerializable()
class APISearchDownloadablesParameters {
  final String keyword;
  final int limit;
  APISearchDownloadablesParameters({
    required this.keyword,
    this.limit = 20,
  });

  factory APISearchDownloadablesParameters.fromJson(
          Map<String, dynamic> json) =>
      _$APISearchDownloadablesParametersFromJson(json);
  Map<String, dynamic> toJson() =>
      _$APISearchDownloadablesParametersToJson(this);
}

@JsonSerializable()
class APIDownloadableData {
  final String type;
  final String name;
  final String id;
  final String url;
  final String thumbnail;
  final List<APIThumbnail> thumbnails;
  final bool isUpcoming;
  final dynamic upcoming;
  final bool isLive;
  final List<dynamic> badges;
  final APIAuthor author;
  final String description;
  final int views;
  final String duration;
  final String uploadedAt;
  final bool alreadyExists;

  APIDownloadableData({
    required this.type,
    required this.name,
    required this.id,
    required this.url,
    required this.thumbnail,
    required this.thumbnails,
    required this.isUpcoming,
    required this.upcoming,
    required this.isLive,
    required this.badges,
    required this.author,
    required this.description,
    required this.views,
    required this.duration,
    required this.uploadedAt,
    required this.alreadyExists,
  });

  factory APIDownloadableData.fromJson(Map<String, dynamic> json) =>
      _$APIDownloadableDataFromJson(json);
  Map<String, dynamic> toJson() => _$APIDownloadableDataToJson(this);
}

@JsonSerializable()
class APIThumbnail {
  final String url;
  final int width;
  final int height;

  APIThumbnail({
    required this.url,
    required this.width,
    required this.height,
  });

  factory APIThumbnail.fromJson(Map<String, dynamic> json) =>
      _$APIThumbnailFromJson(json);
  Map<String, dynamic> toJson() => _$APIThumbnailToJson(this);
}

@JsonSerializable()
class APIAuthor {
  final String name;
  final String channelID;
  final String url;
  final APIAvatar bestAvatar;
  final List<APIAvatar> avatars;
  final List<dynamic> ownerBadges;
  final bool verified;

  APIAuthor({
    required this.name,
    required this.channelID,
    required this.url,
    required this.bestAvatar,
    required this.avatars,
    required this.ownerBadges,
    required this.verified,
  });

  factory APIAuthor.fromJson(Map<String, dynamic> json) =>
      _$APIAuthorFromJson(json);
  Map<String, dynamic> toJson() => _$APIAuthorToJson(this);
}

@JsonSerializable()
class APIAvatar {
  final String url;
  final int width;
  final int height;

  APIAvatar({
    required this.url,
    required this.width,
    required this.height,
  });

  factory APIAvatar.fromJson(Map<String, dynamic> json) =>
      _$APIAvatarFromJson(json);

  Map<String, dynamic> toJson() => _$APIAvatarToJson(this);
}
