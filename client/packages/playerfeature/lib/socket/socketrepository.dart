part of '../playerfeature.dart';

abstract class PlayerSocketRepository {
  StreamController<int> seekDurationFromControlStreamController();
  StreamController<CurrentSong?> currentSongStreamController();
  void seekDurationFromPlayer(int durationInMilliseconds);
  void skipSong();
}
