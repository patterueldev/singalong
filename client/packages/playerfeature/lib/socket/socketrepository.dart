part of '../playerfeature.dart';

abstract class PlayerSocketRepository {
  Future<void> registerIdlePlayer(String playerId, String deviceId);
  void requestPlayerData();
  StreamController<String> get roomAssignedStreamController;
  StreamController<int> get seekDurationFromControlStreamController;
  StreamController<CurrentSong?> get currentSongStreamController;
  StreamController<bool> get togglePlayPauseStreamController;
  StreamController<double> get volumeStreamController;
  void durationUpdate({required int durationInMilliseconds});
  void skipSong();
}
