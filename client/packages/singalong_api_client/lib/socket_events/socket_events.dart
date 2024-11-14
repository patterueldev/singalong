part of '../singalong_api_client.dart';

enum SocketEvent {
  reservedSongs,
  currentSong,
  seekDurationFromPlayer,
  seekDurationFromControl,
  togglePlayPause,
  skipSong,
  adjustVolumeFromControl,
  playersList,
  requestPlayersList,
  roomAssigned,
  ;

  String get value {
    switch (this) {
      case SocketEvent.reservedSongs:
        return 'reservedSongs';
      case SocketEvent.currentSong:
        return 'currentSong';
      case SocketEvent.seekDurationFromPlayer:
        return 'seekDurationFromPlayer';
      case SocketEvent.seekDurationFromControl:
        return 'seekDurationFromControl';
      case SocketEvent.togglePlayPause:
        return 'togglePlayPause';
      case SocketEvent.skipSong:
        return 'skipSong';
      case SocketEvent.adjustVolumeFromControl:
        return 'adjustVolumeFromControl';
      case SocketEvent.playersList:
        return 'playersList';
      case SocketEvent.requestPlayersList:
        return 'requestPlayersList';
      case SocketEvent.roomAssigned:
        return 'roomAssigned';
    }
  }
}
