part of '../playerfeature.dart';

abstract class PlayerViewModel extends ChangeNotifier {
  ValueNotifier<bool> isConnected = ValueNotifier(false);
  ValueNotifier<PlayerViewState> playerViewStateNotifier =
      ValueNotifier(PlayerViewState.loading());
  ValueNotifier<String?> roomIdNotifier = ValueNotifier(null);

  SingalongConfiguration get configuration;

  void setup();
}

class DefaultPlayerViewModel extends PlayerViewModel {
  final ConnectRepository connectRepository;
  final PlayerSocketRepository playerSocketRepository;
  final PersistenceRepository persistenceRepository;
  final ReservedViewModel reservedViewModel;
  final SingalongConfiguration configuration;

  DefaultPlayerViewModel({
    required this.connectRepository,
    required this.playerSocketRepository,
    required this.persistenceRepository,
    required this.reservedViewModel,
    required this.configuration,
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

  bool isSkipping = false;

  @override
  void setup() async {
    isConnected.value = false;
    playerViewStateNotifier.value = PlayerViewState.loading();

    // TODO: Handle unique name to be truly unique, like get it from the server instead of local generation
    final username = await persistenceRepository.getUniqueName();
    final deviceId = await persistenceRepository.getDeviceId();
    await playerSocketRepository.registerIdlePlayer(username, deviceId);

    debugPrint("Player connecting to the server");
    isConnected.value = true;
    playerViewStateNotifier.value = PlayerViewState.disconnected();

    _roomAssignedStreamController =
        playerSocketRepository.roomAssignedStreamController;
    _roomAssignedStreamController?.stream.listen((roomId) {
      debugPrint("Room assigned: $roomId");
      // re-establish connection
      establishConnection(roomId);
    });

    playerSocketRepository.checkIfAssignedToRoom(username);
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

    await connectRepository.connectRoomSocket(roomId);

    setupListeners();
    reservedViewModel.setupListeners();

    playerSocketRepository.requestPlayerData();
  }

  void setupListeners() {
    // 2. Listen to the current song updates
    debugPrint("Listening to current song updates");

    // Listen to the current song stream
    _currentSongController = playerSocketRepository.currentSongStreamController;
    _currentSongController?.stream.listen((currentSong) async {
      debugPrint("Current song: $currentSong");
      try {
        await _clearVideoControllers();
        if (currentSong == null) {
          playerViewStateNotifier.value = PlayerViewState.connected();
          return;
        }
        final durationInSeconds = currentSong.durationInSeconds;
        final videoUrl = currentSong.videoURL;
        debugPrint("Playing video: $videoUrl");
        final controller = VideoController.network(videoUrl);
        controller.setVolume(currentSong.volume);
        _activeSongVideoController = controller;
        _videoControllers.add(controller);

        await controller.initialize();
        playerViewStateNotifier.value =
            PlayerViewState.playing(controller, durationInSeconds.toDouble());
        await controller.play();

        controller.addListener(() {
          _videoPlayerListener(controller);
        });

        isSkipping = false;
        debugPrint("Playing video: $videoUrl");
      } catch (e, s) {
        debugPrint("Error: $e");
        playerViewStateNotifier.value = PlayerViewState.failure(e.toString());
      }
    });

    // Seek duration from the control stream
    _seekDurationFromControlStreamController =
        playerSocketRepository.seekDurationFromControlStreamController;
    _seekDurationFromControlStreamController?.stream.listen((seekValue) {
      debugPrint("Seek value: $seekValue");
      _activeSongVideoController?.seekTo(Duration(seconds: seekValue));
    });

    // Toggle play/pause stream
    _togglePlayPauseStreamController =
        playerSocketRepository.togglePlayPauseStreamController;
    _togglePlayPauseStreamController?.stream.listen((isPlaying) {
      debugPrint("Toggle play/pause: $isPlaying");
      if (isPlaying) {
        _activeSongVideoController?.play();
      } else {
        _activeSongVideoController?.pause();
      }
    });

    // Volume stream
    _volumeStreamController = playerSocketRepository.volumeStreamController;
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

      final audioUrl = "http://$host:9000/assets/fanfare-sound.mp3";
      final audioController = VideoController.network(audioUrl);

      _videoControllers.add(scoreVideoController);
      _videoControllers.add(audioController);

      await scoreVideoController.initialize();
      await audioController.initialize();

      scoreVideoController.setLooping(true);

      await scoreVideoController.play();
      await audioController.play();

      final score = generateRandomScore();
      final message = messageForScore(score);
      playerViewStateNotifier.value = PlayerViewState.score(
        PlayerViewScore(
          score: score,
          message: message,
          videoPlayerController: scoreVideoController,
          audioPlayerController: audioController,
        ),
      );

      isSkipping = false;
      debugPrint("Playing score video: $url");
      audioController.addListener(() {
        _scoreAudioListener(audioController);
      });
    } else {
      // send the current position to the server
      playerSocketRepository.durationUpdate(
          durationInMilliseconds: position.inMilliseconds);

      final state = playerViewStateNotifier.value;
      if (state is PlayerViewPlaying) {
        state.currentSeekValueNotifier.value = position.inSeconds.toDouble();
      }
    }
  }

  int generateRandomScore() {
    final random = Random();
    final randomValue = random.nextInt(100);

    if (randomValue < 50) {
      return 100;
    } else if (randomValue < 90) {
      return 90 + random.nextInt(10);
    } else {
      return 80 + random.nextInt(10);
    }
  }

  String messageForScore(int score) {
    if (score == 100) {
      return "Fantastic!";
    } else if (score >= 90) {
      return "Amazing voice!";
    } else {
      return "Great singing!";
    }
  }

  void _scoreAudioListener(VideoController controller) async {
    final minSeconds = min(8, controller.value.duration.inSeconds);
    final duration = Duration(seconds: minSeconds);
    if (controller.value.position >= duration) {
      controller.pause();
      playerViewStateNotifier.value = PlayerViewState.connected();
      await _clearVideoControllers();
      debugPrint("Is Skipping: $isSkipping");
      if (!isSkipping) {
        debugPrint("Score video finished; playing next song");
        playerSocketRepository.skipSong(completed: true);
        isSkipping = true;
      }
    }
  }

  Future<void> _clearVideoControllers() async {
    // reverse loop to avoid concurrent modification
    for (var i = _videoControllers.length - 1; i >= 0; i--) {
      final controller = _videoControllers[i];
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
