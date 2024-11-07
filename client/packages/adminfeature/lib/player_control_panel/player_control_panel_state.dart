part of '../adminfeature.dart';

class PlayerControlPanelState {
  final PlayerControlPanelStatus status;

  PlayerControlPanelState(this.status);

  factory PlayerControlPanelState.inactive() =>
      PlayerControlPanelState(PlayerControlPanelStatus.inactive);
}

class ActiveState extends PlayerControlPanelState {
  final String title;
  final String artist;
  final String thumbnailURL;
  final double minSeekValue;
  final double maxSeekValue;
  final double minVolumeValue;
  final double maxVolumeValue;

  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(true);

  ActiveState({
    required this.title,
    required this.artist,
    required this.thumbnailURL,
    this.minSeekValue = 0.0,
    required this.maxSeekValue,
    this.minVolumeValue = 0.0,
    this.maxVolumeValue = 1.0,
  }) : super(PlayerControlPanelStatus.active);
}

enum PlayerControlPanelStatus {
  inactive, // nothing is playing
  active, // something is playing
}
