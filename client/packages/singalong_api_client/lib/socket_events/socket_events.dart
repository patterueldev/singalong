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
      case SocketEvent.durationUpdate:
        return 'durationUpdate';
      case SocketEvent.seekDuration:
        return 'seekDuration';
      case SocketEvent.togglePlayPause:
        return 'togglePlayPause';
      case SocketEvent.adjustVolumeFromControl:
        return 'adjustVolumeFromControl';
      case SocketEvent.playersList:
        return 'playersList';
      case SocketEvent.roomAssigned:
        return 'roomAssigned';
    }
  }
}
