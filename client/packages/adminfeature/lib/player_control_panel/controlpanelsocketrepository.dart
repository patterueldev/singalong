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

class CurrentSong {
  final String id;
  final String title;
  final String artist;
  final String thumbnailURL;
  final String videoURL;
  final int durationInSeconds;
  final String reservingUser; //TODO: This will be an actual user object

  CurrentSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailURL,
    required this.videoURL,
    required this.durationInSeconds,
    required this.reservingUser,
  });
}
