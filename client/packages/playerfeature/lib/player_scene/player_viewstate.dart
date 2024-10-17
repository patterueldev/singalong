part of '../playerfeature.dart';

class PlayerViewState {
  const PlayerViewState(this.status);

  final PlayerViewStatus status;

  factory PlayerViewState.idle() =>
      const PlayerViewState(PlayerViewStatus.idle);
  factory PlayerViewState.playing(
          VideoPlayerController videoPlayerController) =>
      PlayerViewPlaying(videoPlayerController: videoPlayerController);
}

class PlayerViewPlaying extends PlayerViewState {
  final VideoPlayerController videoPlayerController;
  const PlayerViewPlaying({
    required this.videoPlayerController,
  }) : super(PlayerViewStatus.playing);
}

enum PlayerViewStatus {
  idle,
  playing,
}
