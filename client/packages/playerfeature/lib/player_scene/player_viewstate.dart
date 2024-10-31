part of '../playerfeature.dart';

class PlayerViewState {
  const PlayerViewState(this.status);

  final PlayerViewStatus status;

  factory PlayerViewState.idle() =>
      const PlayerViewState(PlayerViewStatus.idle);
  factory PlayerViewState.connecting() =>
      const PlayerViewState(PlayerViewStatus.connecting);
  factory PlayerViewState.connected() =>
      const PlayerViewState(PlayerViewStatus.connected);
  factory PlayerViewState.loading() =>
      const PlayerViewState(PlayerViewStatus.loading);
  factory PlayerViewState.playing(
          VideoPlayerController videoPlayerController) =>
      PlayerViewPlaying(videoPlayerController: videoPlayerController);
  factory PlayerViewState.score(int score) => PlayerViewScore(score: score);
  factory PlayerViewState.failure(String errorMessage) =>
      PlayerViewFailure(errorMessage: errorMessage);
}

class PlayerViewPlaying extends PlayerViewState {
  final VideoPlayerController videoPlayerController;
  const PlayerViewPlaying({
    required this.videoPlayerController,
  }) : super(PlayerViewStatus.playing);
}

class PlayerViewScore extends PlayerViewState {
  final int score;
  const PlayerViewScore({
    required this.score,
  }) : super(PlayerViewStatus.score);
}

class PlayerViewFailure extends PlayerViewState {
  final String errorMessage;
  const PlayerViewFailure({
    required this.errorMessage,
  }) : super(PlayerViewStatus.failure);
}

enum PlayerViewStatus {
  idle,
  connecting,
  connected,
  loading,
  playing,
  score,
  failure;

  @override
  String toString() {
    switch (this) {
      case PlayerViewStatus.idle:
        return 'idle';
      case PlayerViewStatus.loading:
        return 'loading';
      case PlayerViewStatus.connecting:
        return 'connecting';
      case PlayerViewStatus.connected:
        return 'connected';
      case PlayerViewStatus.playing:
        return 'playing';
      case PlayerViewStatus.score:
        return 'score';
      case PlayerViewStatus.failure:
        return 'failure';
    }
  }
}
