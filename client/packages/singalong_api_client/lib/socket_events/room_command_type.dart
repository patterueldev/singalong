part of '../singalong_api_client.dart';

enum RoomCommandType {
  skipSong,
  togglePlayPause,
  adjustVolume,
  durationUpdate,
  seekDuration,
  ;

  String get value {
    switch (this) {
      case skipSong:
        return 'skipSong';
      case togglePlayPause:
        return 'togglePlayPause';
      case adjustVolume:
        return 'adjustVolume';
      case durationUpdate:
        return 'durationUpdate';
      case seekDuration:
        return 'seekDuration';
    }
  }
}
