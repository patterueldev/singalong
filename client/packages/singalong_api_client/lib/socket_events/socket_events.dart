part of '../singalong_api_client.dart';

enum SocketEvent {
  reservedSongs,
  currentSong,
  seekDurationFromPlayer,
  seekDurationFromControl,
  pauseSong,
  playSong,
  skipSong,
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
      case SocketEvent.pauseSong:
        return 'pauseSong';
      case SocketEvent.playSong:
        return 'playSong';
      case SocketEvent.skipSong:
        return 'skipSong';
    }
  }
}
