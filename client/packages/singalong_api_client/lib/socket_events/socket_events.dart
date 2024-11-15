part of '../singalong_api_client.dart';

enum SocketEvent {
  roomDataRequest,
  reservedSongs,
  currentSong,
  roomPlayerCommand,
  durationUpdate,
  seekDuration,
  togglePlayPause,
  adjustVolumeFromControl,
  playersList,
  roomAssigned,
  ;

  String get value {
    switch (this) {
      case roomDataRequest:
        return 'roomDataRequest';
      case reservedSongs:
        return 'reservedSongs';
      case currentSong:
        return 'currentSong';
      case roomPlayerCommand:
        return 'roomPlayerCommand';
      case durationUpdate:
        return 'durationUpdate';
      case seekDuration:
        return 'seekDuration';
      case togglePlayPause:
        return 'togglePlayPause';
      case adjustVolumeFromControl:
        return 'adjustVolumeFromControl';
      case playersList:
        return 'playersList';
      case roomAssigned:
        return 'roomAssigned';
    }
  }
}
