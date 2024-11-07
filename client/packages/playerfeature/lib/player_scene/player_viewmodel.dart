part of '../playerfeature.dart';

abstract class PlayerViewModel extends ChangeNotifier {
  ValueNotifier<bool> get isConnected;
  ValueNotifier<PlayerViewState> get playerViewStateNotifier;
  void establishConnection();
}

class DefaultPlayerViewModel extends PlayerViewModel {
  final ConnectRepository connectRepository;
  final PlayerSocketRepository playerSocketRepository;
  final ReservedViewModel reservedViewModel;

  DefaultPlayerViewModel({
    required this.connectRepository,
    required this.playerSocketRepository,
    required this.reservedViewModel,
  });

  late final AuthorizeConnectionUseCase connectUseCase =
      AuthorizeConnectionUseCase(connectRepository: connectRepository);

  // StreamSubscription? _currentSongListener;
  StreamController<CurrentSong?>? _currentSongController;
  StreamController<int>? _seekDurationFromControlStreamController;
  StreamController<bool>? _togglePlayPauseStreamController;

  final List<VideoController> _videoControllers = [];
  VideoController? _activeSongVideoController;

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
        clientType: ClientType.PLAYER,
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

    _currentSongController =
        playerSocketRepository.currentSongStreamController();
    _currentSongController?.stream.listen((currentSong) async {
      debugPrint("Current song: $currentSong");
      try {
        await _clearVideoControllers();
        if (currentSong == null) {
          playerViewStateNotifier.value = PlayerViewState.connected();
          return;
        }
        final videoUrl = currentSong.videoURL;
        debugPrint("Playing video: $videoUrl");
        final controller = VideoController.network(videoUrl);
        _videoControllers.add(controller);
        await controller.initialize();
        playerViewStateNotifier.value = PlayerViewState.playing(controller);

        await controller.play();
        _activeSongVideoController = controller;

        controller.addListener(() {
          _videoPlayerListener(controller);
        });
      } catch (e, s) {
        debugPrint("Error: $e");
        playerViewStateNotifier.value = PlayerViewState.failure(e.toString());
      }
    });

    _seekDurationFromControlStreamController =
        playerSocketRepository.seekDurationFromControlStreamController();
    _seekDurationFromControlStreamController?.stream.listen((seekValue) {
      debugPrint("Seek value: $seekValue");
      _activeSongVideoController?.seekTo(Duration(seconds: seekValue));
    });

    _togglePlayPauseStreamController =
        playerSocketRepository.togglePlayPauseStreamController();
    _togglePlayPauseStreamController?.stream.listen((isPlaying) {
      debugPrint("Toggle play/pause: $isPlaying");
      if (isPlaying) {
        _activeSongVideoController?.play();
      } else {
        _activeSongVideoController?.pause();
      }
    });
  }

  void _videoPlayerListener(VideoController controller) async {
    final position = controller.value.position;
    if (position >= controller.value.duration) {
      controller.pause();
      // TODO: Maybe some video score calculation here
      final host = "thursday.local"; // TODO: this should be configurable
      final url = "http://$host:9000/assets/fireworks.mp4";
      final scoreVideoController = VideoController.network(url);
      _videoControllers.add(scoreVideoController);
      await scoreVideoController.initialize();
      await scoreVideoController.play();
      playerViewStateNotifier.value = PlayerViewState.score(PlayerViewScore(
        score: 100,
        message: "You are a great singer!",
        videoPlayerController: scoreVideoController,
      ));

      scoreVideoController.addListener(() {
        _scoreVideoListener(scoreVideoController);
      });

      // TODO: Send command to the server to update the score and play the next song
    } else {
      // send the current position to the server
      playerSocketRepository.seekDurationFromPlayer(position.inMilliseconds);
    }
  }

  void _scoreVideoListener(VideoController controller) async {
    final minSeconds = min(10, controller.value.duration.inSeconds);
    final duration = Duration(seconds: minSeconds);
    if (controller.value.position >= duration) {
      controller.pause();
      playerViewStateNotifier.value = PlayerViewState.connected();
      await _clearVideoControllers();
      // TODO: Send command to the server to update the score and play the next song
      playerSocketRepository.skipSong();
    }
  }

  Future<void> _clearVideoControllers() async {
    for (final controller in _videoControllers) {
      await controller.pause();
      await controller.dispose();
    }
    _videoControllers.clear();
  }

  @override
  void dispose() async {
    await _clearVideoControllers();

    _currentSongController?.close();
    _seekDurationFromControlStreamController?.close();
    _togglePlayPauseStreamController?.close();
    playerViewStateNotifier.value = PlayerViewState.disconnected();

    super.dispose();
  }
}
