part of '../playerfeature.dart';

abstract class PlayerSocketRepository {
  StreamController<String> get roomAssignedStreamController;
  StreamController<PlayerConnection> playerConnectionStreamController();
  StreamController<int> seekDurationFromControlStreamController();
  StreamController<CurrentSong?> currentSongStreamController();
  StreamController<bool> togglePlayPauseStreamController();
  StreamController<double> volumeStreamController();
  void seekDurationFromPlayer(int durationInMilliseconds);
  void skipSong();
}

class PlayerConnection {}
