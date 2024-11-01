part of '../playerfeature.dart';

abstract class PlayerViewModel extends ChangeNotifier {
  ValueNotifier<bool> get isConnected;
  ValueNotifier<PlayerViewState> get playerViewStateNotifier;
  void establishConnection();
}

class DefaultPlayerViewModel extends PlayerViewModel {
  final AuthorizeConnectionUseCase connectUseCase;
  final ListenToCurrentSongUpdatesUseCase listenToCurrentSongUpdatesUseCase;
  final ConnectRepository connectRepository;
  final ReservedViewModel reservedViewModel;

  DefaultPlayerViewModel({
    required this.connectUseCase,
    required this.listenToCurrentSongUpdatesUseCase,
    required this.connectRepository,
    required this.reservedViewModel,
  });

  StreamSubscription? _currentSongListener;

  @override
  final ValueNotifier<bool> isConnected = ValueNotifier(false);

  @override
  final ValueNotifier<PlayerViewState> playerViewStateNotifier =
      ValueNotifier(PlayerViewState.loading());

  @override
  void establishConnection() async {
    isConnected.value = false;
    playerViewStateNotifier.value = PlayerViewState.loading();

    // the process will be as follows:
    // 1. Connect to the server with username and roomId
    var canProceed = false;
    // TODO: THESE will probably be managed by an admin device in the future; for now, we'll just hardcode it
    debugPrint("Player connecting to the server");
    final connectResult = await connectUseCase(
      ConnectParameters(
        username: "player",
        roomId: "569841",
        clientType: "PLAYER",
      ),
    );
    connectResult.fold(
      (l) {
        debugPrint("Error: $l");
        playerViewStateNotifier.value = PlayerViewState.failure(l.toString());
      },
      (r) {
        canProceed = true;
      },
    );

    if (!canProceed) {
      playerViewStateNotifier.value =
          PlayerViewState.failure("Unable to connect to the server");
      return;
    }
    isConnected.value = true;

    playerViewStateNotifier.value = PlayerViewState.disconnected();
    setupListeners();
    reservedViewModel.setupListeners();

    connectRepository.connectSocket();
  }

  void setupListeners() {
    // 2. Listen to the current song updates
    debugPrint("Listening to current song updates");
    _currentSongListener =
        listenToCurrentSongUpdatesUseCase().listen((currentSong) async {
      debugPrint("Current song: $currentSong");
      try {
        final currentState = playerViewStateNotifier.value;
        if (currentState is PlayerViewPlaying) {
          await currentState.videoPlayerController.pause();
          await currentState.videoPlayerController.dispose();
        }
        if (currentSong == null) {
          playerViewStateNotifier.value = PlayerViewState.connected();
          return;
        }
        final videoUrl = currentSong.videoURL;
        debugPrint("Playing video: $videoUrl");
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
        );
        await controller.initialize();
        playerViewStateNotifier.value = PlayerViewState.playing(controller);

        await controller.play();
      } catch (e, s) {
        debugPrint("Error: $e");
        playerViewStateNotifier.value = PlayerViewState.failure(e.toString());
      }
    });
  }

  @override
  void dispose() {
    _currentSongListener?.cancel();
    final currentState = playerViewStateNotifier.value;
    if (currentState is PlayerViewPlaying) {
      currentState.videoPlayerController.pause();
      currentState.videoPlayerController.dispose();
    }
    playerViewStateNotifier.value = PlayerViewState.disconnected();

    super.dispose();
  }
}
