part of '../playerfeature.dart';

abstract class PlayerViewModel {
  ValueNotifier<PlayerViewState> get playerViewStateNotifier;
  ValueNotifier<bool> get isLoadingNotifier;

  void load();
}

class DefaultPlayerViewModel implements PlayerViewModel {
  DefaultPlayerViewModel();

  @override
  final ValueNotifier<PlayerViewState> playerViewStateNotifier =
      ValueNotifier(PlayerViewState.idle());

  @override
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);

  @override
  void load() async {
    debugPrint('Loading video');
    isLoadingNotifier.value = true;

    // Simulate loading
    await Future.delayed(const Duration(seconds: 2));

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4'),
    );
    await controller.initialize();
    playerViewStateNotifier.value = PlayerViewState.playing(controller);
    isLoadingNotifier.value = false;

    await controller.play();
  }
}
