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

/*
{
            "type": "video",
            "name": "Karaoke ♬ Ethyria - God Sees All | NIJISANJI EN【Off Vocal | Instrumental】",
            "id": "O7W8ukOMhnA",
            "url": "https://www.youtube.com/watch?v=O7W8ukOMhnA",
            "thumbnail": "https://i.ytimg.com/vi/O7W8ukOMhnA/hq720.jpg?sqp=-oaymwEXCNAFEJQDSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLBLwC0VX_YSr_gSGemxaeI2RQIa4g",
            "thumbnails": [
                {
                    "url": "https://i.ytimg.com/vi/O7W8ukOMhnA/hq720.jpg?sqp=-oaymwEXCNAFEJQDSFryq4qpAwkIARUAAIhCGAE=&rs=AOn4CLBLwC0VX_YSr_gSGemxaeI2RQIa4g",
                    "width": 720,
                    "height": 404
                },
                {
                    "url": "https://i.ytimg.com/vi/O7W8ukOMhnA/hq720.jpg?sqp=-oaymwEjCOgCEMoBSFryq4qpAxUIARUAAAAAGAElAADIQj0AgKJDeAE=&rs=AOn4CLBaFjJlxIUiTu0bKM4anhzxw5YfUA",
                    "width": 360,
                    "height": 202
                }
            ],
            "isUpcoming": false,
            "upcoming": null,
            "isLive": false,
            "badges": [],
            "author": {
                "name": "DokiDoki Karaoke Ch",
                "channelID": "UC5j6NlG-WyrDibiCcbvK7LQ",
                "url": "https://www.youtube.com/@dokidokikara",
                "bestAvatar": {
                    "url": "https://yt3.ggpht.com/k-o3mL2qsh6cV4Ngk5Iz-SfQLSNrHfKdUqgOQsFfurpUGNgWYSDSN5CecXXBTxFf4bTWUraWLU4=s68-c-k-c0x00ffffff-no-rj",
                    "width": 68,
                    "height": 68
                },
                "avatars": [
                    {
                        "url": "https://yt3.ggpht.com/k-o3mL2qsh6cV4Ngk5Iz-SfQLSNrHfKdUqgOQsFfurpUGNgWYSDSN5CecXXBTxFf4bTWUraWLU4=s68-c-k-c0x00ffffff-no-rj",
                        "width": 68,
                        "height": 68
                    }
                ],
                "ownerBadges": [],
                "verified": false
            },
            "description": "",
            "views": 9201,
            "duration": "3:21",
            "uploadedAt": "1 year ago",
            "alreadyExists": false
        }
 */
