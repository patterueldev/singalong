part of '../playerfeature.dart';

abstract class PlayerViewModel extends ChangeNotifier {
  ValueNotifier<bool> isConnected = ValueNotifier(false);
  ValueNotifier<PlayerViewState> playerViewStateNotifier =
      ValueNotifier(PlayerViewState.loading());
  ValueNotifier<String?> roomIdNotifier = ValueNotifier(null);

  void setup();
}

class DefaultPlayerViewModel extends PlayerViewModel {
  final ConnectRepository connectRepository;
  final PlayerSocketRepository playerSocketRepository;
  final PersistenceRepository persistenceRepository;
  final ReservedViewModel reservedViewModel;

  DefaultPlayerViewModel({
    required this.connectRepository,
    required this.playerSocketRepository,
    required this.persistenceRepository,
    required this.reservedViewModel,
  }) {
    setup();
  }

  late final AuthorizeConnectionUseCase connectUseCase =
      AuthorizeConnectionUseCase(connectRepository: connectRepository);

  // StreamSubscription? _currentSongListener;
  StreamController<String>? _roomAssignedStreamController;
  StreamController<CurrentSong?>? _currentSongController;
  StreamController<int>? _seekDurationFromControlStreamController;
  StreamController<bool>? _togglePlayPauseStreamController;
  StreamController<double>? _volumeStreamController;

  final List<VideoController> _videoControllers = [];
  VideoController? _activeSongVideoController;

  @override
  void setup() async {
    isConnected.value = false;
    playerViewStateNotifier.value = PlayerViewState.loading();

    // initial connection
    final username = await persistenceRepository.getUniqueName();
    final connectResult = await connectUseCase(
      ConnectParameters(
        username: username,
        roomId: "idle",
        roomPasscode: "idle",
        clientType: ClientType.PLAYER,
      ),
    );

    debugPrint("Player connecting to the server");
    connectResult.fold(
      (l) {
        debugPrint("Error: $l");
        playerViewStateNotifier.value = PlayerViewState.failure(l.toString());
      },
      (r) {
        connectRepository.connectSocket();
        isConnected.value = true;
        playerViewStateNotifier.value = PlayerViewState.disconnected();
      },
    );

    _roomAssignedStreamController =
        playerSocketRepository.roomAssignedStreamController;
    _roomAssignedStreamController?.stream.listen((roomId) {
      debugPrint("Room assigned: $roomId");
      // re-establish connection
      establishConnection(roomId);
    });
  }

  void establishConnection(String roomId) async {
    debugPrint("Establishing connection to the room: $roomId");
    isConnected.value = false;
    playerViewStateNotifier.value = PlayerViewState.loading();

    final username = await persistenceRepository.getUniqueName();

    debugPrint("Room assigned: $roomId");
    final connectResult = await connectUseCase(
      ConnectParameters(
        username: username,
        roomId: roomId,
        clientType: ClientType.PLAYER,
      ),
    );

    // 1. Connect to the server with username and roomId
    var canProceed = false;
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
    roomIdNotifier.value = roomId;
    playerViewStateNotifier.value = PlayerViewState.connected();

    setupListeners();
    reservedViewModel.setupListeners();

    connectRepository.connectSocket();
  }

  void setupListeners() {
    // 2. Listen to the current song updates
    debugPrint("Listening to current song updates");

    // Listen to the current song stream
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

    // Seek duration from the control stream
    _seekDurationFromControlStreamController =
        playerSocketRepository.seekDurationFromControlStreamController();
    _seekDurationFromControlStreamController?.stream.listen((seekValue) {
      debugPrint("Seek value: $seekValue");
      _activeSongVideoController?.seekTo(Duration(seconds: seekValue));
    });

    // Toggle play/pause stream
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

    // Volume stream
    _volumeStreamController = playerSocketRepository.volumeStreamController();
    _volumeStreamController?.stream.listen((volume) {
      debugPrint("Volume: $volume");
      _activeSongVideoController?.setVolume(volume);
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
    _volumeStreamController?.close();
    playerViewStateNotifier.value = PlayerViewState.disconnected();

    super.dispose();
  }
}
