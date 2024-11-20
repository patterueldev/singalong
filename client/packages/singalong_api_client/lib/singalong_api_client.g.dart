// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'singalong_api_client.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RoomCommand _$RoomCommandFromJson(Map<String, dynamic> json) => RoomCommand(
      $enumDecode(_$RoomCommandTypeEnumMap, json['type']),
      json['data'],
    );

Map<String, dynamic> _$RoomCommandToJson(RoomCommand instance) =>
    <String, dynamic>{
      'type': _$RoomCommandTypeEnumMap[instance.type]!,
      'data': instance.data,
    };

const _$RoomCommandTypeEnumMap = {
  RoomCommandType.skipSong: 'skipSong',
  RoomCommandType.togglePlayPause: 'togglePlayPause',
  RoomCommandType.adjustVolume: 'adjustVolume',
  RoomCommandType.durationUpdate: 'durationUpdate',
  RoomCommandType.seekDuration: 'seekDuration',
};

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
      deviceId: json['deviceId'] as String,
    );

Map<String, dynamic> _$APIConnectParametersToJson(
        APIConnectParameters instance) =>
    <String, dynamic>{
      'username': instance.username,
      'userPasscode': instance.userPasscode,
      'roomId': instance.roomId,
      'roomPasscode': instance.roomPasscode,
      'clientType': instance.clientType,
      'deviceId': instance.deviceId,
    };

APIConnectResponseData _$APIConnectResponseDataFromJson(
        Map<String, dynamic> json) =>
    APIConnectResponseData(
      requiresUserPasscode: json['requiresUserPasscode'] as bool?,
      requiresRoomPasscode: json['requiresRoomPasscode'] as bool?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
    );

Map<String, dynamic> _$APIConnectResponseDataToJson(
        APIConnectResponseData instance) =>
    <String, dynamic>{
      'requiresUserPasscode': instance.requiresUserPasscode,
      'requiresRoomPasscode': instance.requiresRoomPasscode,
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
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
      durationInSeconds: (json['durationInSeconds'] as num).toInt(),
      reservingUser: json['reservingUser'] as String,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$APICurrentSongToJson(APICurrentSong instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artist': instance.artist,
      'thumbnailPath': instance.thumbnailPath,
      'videoPath': instance.videoPath,
      'durationInSeconds': instance.durationInSeconds,
      'reservingUser': instance.reservingUser,
      'volume': instance.volume,
    };

APIPaginatedSongs _$APIPaginatedSongsFromJson(Map<String, dynamic> json) =>
    APIPaginatedSongs(
      items: (json['items'] as List<dynamic>)
          .map((e) => APISongItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextOffset: (json['nextOffset'] as num?)?.toInt(),
      nextCursor: json['nextCursor'] as String?,
      nextPage: (json['nextPage'] as num?)?.toInt(),
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
      alreadyPlayedInRoom: json['alreadyPlayedInRoom'] as bool,
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
      'alreadyPlayedInRoom': instance.alreadyPlayedInRoom,
    };

APILoadSongsParameters _$APILoadSongsParametersFromJson(
        Map<String, dynamic> json) =>
    APILoadSongsParameters(
      keyword: json['keyword'] as String?,
      limit: (json['limit'] as num?)?.toInt(),
      nextOffset: (json['nextOffset'] as num?)?.toInt(),
      nextCursor: json['nextCursor'] as String?,
      nextPage: (json['nextPage'] as num?)?.toInt(),
      roomId: json['roomId'] as String?,
    );

Map<String, dynamic> _$APILoadSongsParametersToJson(
        APILoadSongsParameters instance) =>
    <String, dynamic>{
      'keyword': instance.keyword,
      'limit': instance.limit,
      'nextOffset': instance.nextOffset,
      'nextCursor': instance.nextCursor,
      'nextPage': instance.nextPage,
      'roomId': instance.roomId,
    };

APIReserveSongParameters _$APIReserveSongParametersFromJson(
        Map<String, dynamic> json) =>
    APIReserveSongParameters(
      songId: json['songId'] as String,
    );

Map<String, dynamic> _$APIReserveSongParametersToJson(
        APIReserveSongParameters instance) =>
    <String, dynamic>{
      'songId': instance.songId,
    };

APIIdentifiedSongDetails _$APIIdentifiedSongDetailsFromJson(
        Map<String, dynamic> json) =>
    APIIdentifiedSongDetails(
      id: json['id'] as String,
      source: json['source'] as String,
      imageUrl: json['imageUrl'] as String,
      songTitle: json['songTitle'] as String,
      songArtist: json['songArtist'] as String,
      songLanguage: json['songLanguage'] as String,
      isOffVocal: json['isOffVocal'] as bool,
      videoHasLyrics: json['videoHasLyrics'] as bool,
      songLyrics: json['songLyrics'] as String,
      lengthSeconds: (json['lengthSeconds'] as num).toInt(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      genres:
          (json['genres'] as List<dynamic>).map((e) => e as String).toList(),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      alreadyExists: json['alreadyExists'] as bool,
    );

Map<String, dynamic> _$APIIdentifiedSongDetailsToJson(
        APIIdentifiedSongDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source': instance.source,
      'imageUrl': instance.imageUrl,
      'songTitle': instance.songTitle,
      'songArtist': instance.songArtist,
      'songLanguage': instance.songLanguage,
      'isOffVocal': instance.isOffVocal,
      'videoHasLyrics': instance.videoHasLyrics,
      'songLyrics': instance.songLyrics,
      'lengthSeconds': instance.lengthSeconds,
      'metadata': instance.metadata,
      'genres': instance.genres,
      'tags': instance.tags,
      'alreadyExists': instance.alreadyExists,
    };

APIIdentifySongParameters _$APIIdentifySongParametersFromJson(
        Map<String, dynamic> json) =>
    APIIdentifySongParameters(
      url: json['url'] as String,
    );

Map<String, dynamic> _$APIIdentifySongParametersToJson(
        APIIdentifySongParameters instance) =>
    <String, dynamic>{
      'url': instance.url,
    };

APISaveSongParameters _$APISaveSongParametersFromJson(
        Map<String, dynamic> json) =>
    APISaveSongParameters(
      thenReserve: json['thenReserve'] as bool,
      song: APIIdentifiedSongDetails.fromJson(
          json['song'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$APISaveSongParametersToJson(
        APISaveSongParameters instance) =>
    <String, dynamic>{
      'thenReserve': instance.thenReserve,
      'song': instance.song,
    };

APISaveSongResponseData _$APISaveSongResponseDataFromJson(
        Map<String, dynamic> json) =>
    APISaveSongResponseData(
      id: json['id'] as String,
      source: json['source'] as String,
      sourceId: json['sourceId'] as String,
      thumbnailPath: json['thumbnailPath'] as String?,
      videoPath: json['videoPath'] as String?,
      songTitle: json['songTitle'] as String,
      songArtist: json['songArtist'] as String,
      songLanguage: json['songLanguage'] as String,
      isOffVocal: json['isOffVocal'] as bool,
      videoHasLyrics: json['videoHasLyrics'] as bool,
      songLyrics: json['songLyrics'] as String,
      lengthSeconds: (json['lengthSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$APISaveSongResponseDataToJson(
        APISaveSongResponseData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source': instance.source,
      'sourceId': instance.sourceId,
      'thumbnailPath': instance.thumbnailPath,
      'videoPath': instance.videoPath,
      'songTitle': instance.songTitle,
      'songArtist': instance.songArtist,
      'songLanguage': instance.songLanguage,
      'isOffVocal': instance.isOffVocal,
      'videoHasLyrics': instance.videoHasLyrics,
      'songLyrics': instance.songLyrics,
      'lengthSeconds': instance.lengthSeconds,
    };

APISearchDownloadablesParameters _$APISearchDownloadablesParametersFromJson(
        Map<String, dynamic> json) =>
    APISearchDownloadablesParameters(
      keyword: json['keyword'] as String,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
    );

Map<String, dynamic> _$APISearchDownloadablesParametersToJson(
        APISearchDownloadablesParameters instance) =>
    <String, dynamic>{
      'keyword': instance.keyword,
      'limit': instance.limit,
    };

APIDownloadableData _$APIDownloadableDataFromJson(Map<String, dynamic> json) =>
    APIDownloadableData(
      type: json['type'] as String,
      name: json['name'] as String,
      id: json['id'] as String,
      url: json['url'] as String,
      thumbnail: json['thumbnail'] as String,
      thumbnails: (json['thumbnails'] as List<dynamic>)
          .map((e) => APIThumbnail.fromJson(e as Map<String, dynamic>))
          .toList(),
      isUpcoming: json['isUpcoming'] as bool,
      upcoming: json['upcoming'],
      isLive: json['isLive'] as bool,
      badges: json['badges'] as List<dynamic>,
      author: APIAuthor.fromJson(json['author'] as Map<String, dynamic>),
      description: json['description'] as String,
      views: (json['views'] as num).toInt(),
      duration: json['duration'] as String,
      uploadedAt: json['uploadedAt'] as String,
      alreadyExists: json['alreadyExists'] as bool,
    );

Map<String, dynamic> _$APIDownloadableDataToJson(
        APIDownloadableData instance) =>
    <String, dynamic>{
      'type': instance.type,
      'name': instance.name,
      'id': instance.id,
      'url': instance.url,
      'thumbnail': instance.thumbnail,
      'thumbnails': instance.thumbnails,
      'isUpcoming': instance.isUpcoming,
      'upcoming': instance.upcoming,
      'isLive': instance.isLive,
      'badges': instance.badges,
      'author': instance.author,
      'description': instance.description,
      'views': instance.views,
      'duration': instance.duration,
      'uploadedAt': instance.uploadedAt,
      'alreadyExists': instance.alreadyExists,
    };

APIThumbnail _$APIThumbnailFromJson(Map<String, dynamic> json) => APIThumbnail(
      url: json['url'] as String,
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
    );

Map<String, dynamic> _$APIThumbnailToJson(APIThumbnail instance) =>
    <String, dynamic>{
      'url': instance.url,
      'width': instance.width,
      'height': instance.height,
    };

APIAuthor _$APIAuthorFromJson(Map<String, dynamic> json) => APIAuthor(
      name: json['name'] as String,
      channelID: json['channelID'] as String,
      url: json['url'] as String,
      bestAvatar:
          APIAvatar.fromJson(json['bestAvatar'] as Map<String, dynamic>),
      avatars: (json['avatars'] as List<dynamic>)
          .map((e) => APIAvatar.fromJson(e as Map<String, dynamic>))
          .toList(),
      ownerBadges: json['ownerBadges'] as List<dynamic>,
      verified: json['verified'] as bool,
    );

Map<String, dynamic> _$APIAuthorToJson(APIAuthor instance) => <String, dynamic>{
      'name': instance.name,
      'channelID': instance.channelID,
      'url': instance.url,
      'bestAvatar': instance.bestAvatar,
      'avatars': instance.avatars,
      'ownerBadges': instance.ownerBadges,
      'verified': instance.verified,
    };

APIAvatar _$APIAvatarFromJson(Map<String, dynamic> json) => APIAvatar(
      url: json['url'] as String,
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
    );

Map<String, dynamic> _$APIAvatarToJson(APIAvatar instance) => <String, dynamic>{
      'url': instance.url,
      'width': instance.width,
      'height': instance.height,
    };

APIPaginatedRoomList _$APIPaginatedRoomListFromJson(
        Map<String, dynamic> json) =>
    APIPaginatedRoomList(
      items: (json['items'] as List<dynamic>)
          .map((e) => APIRoomItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextOffset: (json['nextOffset'] as num?)?.toInt(),
      nextCursor: json['nextCursor'] as String?,
      nextPage: (json['nextPage'] as num?)?.toInt(),
    );

Map<String, dynamic> _$APIPaginatedRoomListToJson(
        APIPaginatedRoomList instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextOffset': instance.nextOffset,
      'nextCursor': instance.nextCursor,
      'nextPage': instance.nextPage,
    };

APIRoomItem _$APIRoomItemFromJson(Map<String, dynamic> json) => APIRoomItem(
      id: json['id'] as String,
      name: json['name'] as String,
      isSecured: json['isSecured'] as bool,
      isActive: json['isActive'] as bool,
      lastActive: DateTime.parse(json['lastActive'] as String),
    );

Map<String, dynamic> _$APIRoomItemToJson(APIRoomItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isSecured': instance.isSecured,
      'isActive': instance.isActive,
      'lastActive': instance.lastActive.toIso8601String(),
    };

APILoadRoomListParameters _$APILoadRoomListParametersFromJson(
        Map<String, dynamic> json) =>
    APILoadRoomListParameters(
      keyword: json['keyword'] as String?,
      limit: (json['limit'] as num?)?.toInt(),
      nextOffset: (json['nextOffset'] as num?)?.toInt(),
      nextCursor: json['nextCursor'] as String?,
      nextPage: (json['nextPage'] as num?)?.toInt(),
    );

Map<String, dynamic> _$APILoadRoomListParametersToJson(
        APILoadRoomListParameters instance) =>
    <String, dynamic>{
      'keyword': instance.keyword,
      'limit': instance.limit,
      'nextOffset': instance.nextOffset,
      'nextCursor': instance.nextCursor,
      'nextPage': instance.nextPage,
    };

APIRoom _$APIRoomFromJson(Map<String, dynamic> json) => APIRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      passcode: json['passcode'] as String?,
      isArchived: json['isArchived'] as bool,
    );

Map<String, dynamic> _$APIRoomToJson(APIRoom instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'passcode': instance.passcode,
      'isArchived': instance.isArchived,
    };

APIConnectWithRoomResponseData _$APIConnectWithRoomResponseDataFromJson(
        Map<String, dynamic> json) =>
    APIConnectWithRoomResponseData(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );

Map<String, dynamic> _$APIConnectWithRoomResponseDataToJson(
        APIConnectWithRoomResponseData instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
    };

APIPlayerItem _$APIPlayerItemFromJson(Map<String, dynamic> json) =>
    APIPlayerItem(
      id: json['id'] as String,
      name: json['name'] as String,
      isIdle: json['isIdle'] as bool? ?? false,
    );

Map<String, dynamic> _$APIPlayerItemToJson(APIPlayerItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isIdle': instance.isIdle,
    };

APICreateRoomParameters _$APICreateRoomParametersFromJson(
        Map<String, dynamic> json) =>
    APICreateRoomParameters(
      roomId: json['roomId'] as String,
      roomName: json['roomName'] as String,
      roomPasscode: json['roomPasscode'] as String? ?? '',
    );

Map<String, dynamic> _$APICreateRoomParametersToJson(
        APICreateRoomParameters instance) =>
    <String, dynamic>{
      'roomId': instance.roomId,
      'roomName': instance.roomName,
      'roomPasscode': instance.roomPasscode,
    };

APISongDetails _$APISongDetailsFromJson(Map<String, dynamic> json) =>
    APISongDetails(
      id: json['id'] as String,
      source: json['source'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      language: json['language'] as String,
      isOffVocal: json['isOffVocal'] as bool,
      videoHasLyrics: json['videoHasLyrics'] as bool,
      duration: (json['duration'] as num).toInt(),
      genres:
          (json['genres'] as List<dynamic>).map((e) => e as String).toList(),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      metadata: Map<String, String>.from(json['metadata'] as Map),
      thumbnailPath: json['thumbnailPath'] as String,
      wasReserved: json['wasReserved'] as bool,
      currentPlaying: json['currentPlaying'] as bool,
      lyrics: json['lyrics'] as String?,
      addedBy: json['addedBy'] as String,
      addedAtSession: json['addedAtSession'] as String,
      lastUpdatedBy: json['lastUpdatedBy'] as String,
      isCorrupted: json['isCorrupted'] as bool,
    );

Map<String, dynamic> _$APISongDetailsToJson(APISongDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source': instance.source,
      'title': instance.title,
      'artist': instance.artist,
      'language': instance.language,
      'isOffVocal': instance.isOffVocal,
      'videoHasLyrics': instance.videoHasLyrics,
      'duration': instance.duration,
      'genres': instance.genres,
      'tags': instance.tags,
      'metadata': instance.metadata,
      'thumbnailPath': instance.thumbnailPath,
      'wasReserved': instance.wasReserved,
      'currentPlaying': instance.currentPlaying,
      'lyrics': instance.lyrics,
      'addedBy': instance.addedBy,
      'addedAtSession': instance.addedAtSession,
      'lastUpdatedBy': instance.lastUpdatedBy,
      'isCorrupted': instance.isCorrupted,
    };

APILoadSongDetailsParameters _$APILoadSongDetailsParametersFromJson(
        Map<String, dynamic> json) =>
    APILoadSongDetailsParameters(
      songId: json['songId'] as String,
      roomId: json['roomId'] as String?,
    );

Map<String, dynamic> _$APILoadSongDetailsParametersToJson(
        APILoadSongDetailsParameters instance) =>
    <String, dynamic>{
      'songId': instance.songId,
      'roomId': instance.roomId,
    };

APIUpdateSongParameters _$APIUpdateSongParametersFromJson(
        Map<String, dynamic> json) =>
    APIUpdateSongParameters(
      songId: json['songId'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      language: json['language'] as String,
      isOffVocal: json['isOffVocal'] as bool,
      videoHasLyrics: json['videoHasLyrics'] as bool,
      songLyrics: json['songLyrics'] as String,
      metadata: Map<String, String>.from(json['metadata'] as Map),
      genres:
          (json['genres'] as List<dynamic>).map((e) => e as String).toList(),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$APIUpdateSongParametersToJson(
        APIUpdateSongParameters instance) =>
    <String, dynamic>{
      'songId': instance.songId,
      'title': instance.title,
      'artist': instance.artist,
      'language': instance.language,
      'isOffVocal': instance.isOffVocal,
      'videoHasLyrics': instance.videoHasLyrics,
      'songLyrics': instance.songLyrics,
      'metadata': instance.metadata,
      'genres': instance.genres,
      'tags': instance.tags,
    };
