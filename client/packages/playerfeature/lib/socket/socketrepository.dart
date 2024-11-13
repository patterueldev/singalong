part of '../playerfeature.dart';

abstract class PlayerSocketRepository {
  StreamController<int> seekDurationFromControlStreamController();
  StreamController<CurrentSong?> currentSongStreamController();
  StreamController<bool> togglePlayPauseStreamController();
  StreamController<double> volumeStreamController();
  void seekDurationFromPlayer(int durationInMilliseconds);
  void skipSong();
}
