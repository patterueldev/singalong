part of '../adminfeature.dart';

abstract class ControlPanelSocketRepository {
  void requestControlPanelData();
  StreamController<CurrentSong?> get currentSongStreamController;
  StreamController<int> get durationUpdateInMillisecondsStreamController;
  StreamController<bool> get togglePlayPauseStreamController;
  StreamController<PlayerItem?> get selectedPlayerItemStreamController;
  void seekDuration({required int durationInSeconds});
  void adjustVolumeFromControl(double volume);
  void togglePlayPause(bool isPlaying);
  void skipSong();
}
