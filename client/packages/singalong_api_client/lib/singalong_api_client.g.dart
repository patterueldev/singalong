// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'singalong_api_client.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GenericResponse _$GenericResponseFromJson(Map<String, dynamic> json) =>
    GenericResponse(
      success: json['success'] as bool,
      status: (json['status'] as num).toInt(),
      data: json['data'],
      message: json['message'] as String?,
    );

Map<String, dynamic> _$GenericResponseToJson(GenericResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'status': instance.status,
      'data': instance.data,
      'message': instance.message,
    };

APIConnectParameters _$APIConnectParametersFromJson(
        Map<String, dynamic> json) =>
    APIConnectParameters(
      username: json['username'] as String,
      userPasscode: json['userPasscode'] as String?,
      roomId: json['roomId'] as String,
      roomPasscode: json['roomPasscode'] as String?,
      clientType: json['clientType'] as String,
    );

Map<String, dynamic> _$APIConnectParametersToJson(
        APIConnectParameters instance) =>
    <String, dynamic>{
      'username': instance.username,
      'userPasscode': instance.userPasscode,
      'roomId': instance.roomId,
      'roomPasscode': instance.roomPasscode,
      'clientType': instance.clientType,
    };

APIConnectResponseData _$APIConnectResponseDataFromJson(
        Map<String, dynamic> json) =>
    APIConnectResponseData(
      requiresUserPasscode: json['requiresUserPasscode'] as bool?,
      requiresRoomPasscode: json['requiresRoomPasscode'] as bool?,
      accessToken: json['accessToken'] as String?,
    );

Map<String, dynamic> _$APIConnectResponseDataToJson(
        APIConnectResponseData instance) =>
    <String, dynamic>{
      'requiresUserPasscode': instance.requiresUserPasscode,
      'requiresRoomPasscode': instance.requiresRoomPasscode,
      'accessToken': instance.accessToken,
    };

APIReservedSong _$APIReservedSongFromJson(Map<String, dynamic> json) =>
    APIReservedSong(
      id: json['id'] as String,
      order: (json['order'] as num).toInt(),
      songId: json['songId'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      thumbnailPath: json['thumbnailPath'] as String,
      reservingUser: json['reservingUser'] as String,
      currentPlaying: json['currentPlaying'] as bool,
    );

Map<String, dynamic> _$APIReservedSongToJson(APIReservedSong instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order': instance.order,
      'songId': instance.songId,
      'title': instance.title,
      'artist': instance.artist,
      'thumbnailPath': instance.thumbnailPath,
      'reservingUser': instance.reservingUser,
      'currentPlaying': instance.currentPlaying,
    };

APICurrentSong _$APICurrentSongFromJson(Map<String, dynamic> json) =>
    APICurrentSong(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      thumbnailPath: json['thumbnailPath'] as String,
      videoPath: json['videoPath'] as String,
      reservingUser: json['reservingUser'] as String,
    );

Map<String, dynamic> _$APICurrentSongToJson(APICurrentSong instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artist': instance.artist,
      'thumbnailPath': instance.thumbnailPath,
      'videoPath': instance.videoPath,
      'reservingUser': instance.reservingUser,
    };

APIPaginatedSongs _$APIPaginatedSongsFromJson(Map<String, dynamic> json) =>
    APIPaginatedSongs(
      items: (json['items'] as List<dynamic>)
          .map((e) => APISongItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextOffset: json['nextOffset'],
      nextCursor: json['nextCursor'],
      nextPage: json['nextPage'],
    );

Map<String, dynamic> _$APIPaginatedSongsToJson(APIPaginatedSongs instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextOffset': instance.nextOffset,
      'nextCursor': instance.nextCursor,
      'nextPage': instance.nextPage,
    };

APISongItem _$APISongItemFromJson(Map<String, dynamic> json) => APISongItem(
      id: json['id'] as String,
      thumbnailPath: json['thumbnailPath'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      language: json['language'] as String,
      isOffVocal: json['isOffVocal'] as bool,
      lengthSeconds: (json['lengthSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$APISongItemToJson(APISongItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'thumbnailPath': instance.thumbnailPath,
      'title': instance.title,
      'artist': instance.artist,
      'language': instance.language,
      'isOffVocal': instance.isOffVocal,
      'lengthSeconds': instance.lengthSeconds,
    };

APILoadSongsParameters _$APILoadSongsParametersFromJson(
        Map<String, dynamic> json) =>
    APILoadSongsParameters(
      keyword: json['keyword'] as String?,
      limit: (json['limit'] as num?)?.toInt(),
      nextOffset: json['nextOffset'],
      nextCursor: json['nextCursor'],
      nextPage: json['nextPage'],
    );

Map<String, dynamic> _$APILoadSongsParametersToJson(
        APILoadSongsParameters instance) =>
    <String, dynamic>{
      'keyword': instance.keyword,
      'limit': instance.limit,
      'nextOffset': instance.nextOffset,
      'nextCursor': instance.nextCursor,
      'nextPage': instance.nextPage,
    };
