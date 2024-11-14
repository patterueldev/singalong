part of 'singalong_api_client.dart';

enum APIPath {
  sessionConnect,
  sessionCheck,
  songs,
  reserveSong,
  identifySong,
  downloadable,
  adminRooms,
  adminConnectRoom,
  adminAssignRoom,
  adminGenerateRoomID,
  ;

  String get value {
    switch (this) {
      case sessionConnect:
        return '/session/connect';
      case sessionCheck:
        return '/session/check';
      case songs:
        return '/songs';
      case reserveSong:
        return '/songs/reserve';
      case identifySong:
        return '/songs/identify';
      case downloadable:
        return '/songs/downloadable';
      case adminRooms:
        return '/admin/rooms';
      case adminConnectRoom:
        return '/admin/rooms/connect';
      case adminAssignRoom:
        return '/admin/rooms/assign';
      case adminGenerateRoomID:
        return '/admin/rooms/generateid';
    }
  }
}
