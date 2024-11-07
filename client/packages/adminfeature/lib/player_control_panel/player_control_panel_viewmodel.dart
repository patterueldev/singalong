part of '../adminfeature.dart';

abstract class PlayerControlPanelViewModel extends ChangeNotifier {
  ValueNotifier<PlayerControlPanelState> stateNotifier =
      ValueNotifier(PlayerControlPanelState.inactive());
  ValueNotifier<double> currentSeekValueNotifier = ValueNotifier(0.0);
  ValueNotifier<double> currentVolumeValueNotifier = ValueNotifier(0.5);
  bool isSeeking = false;

  void setup();
  void togglePlayPause(bool isPlaying);
  void nextSong();
  void seek(double value) {
    currentSeekValueNotifier.value = value;
  }

  void toggleSeeking(bool value) {
    isSeeking = value;
  }

  void setVolume(double value) {
    currentVolumeValueNotifier.value = value;
  }
}

class DefaultPlayerControlPanelViewModel extends PlayerControlPanelViewModel {
  final AuthorizeConnectionUseCase authorizeConnectionUseCase;
  final ConnectRepository connectRepository;
  final ControlPanelSocketRepository controlPanelRepository;

  DefaultPlayerControlPanelViewModel({
    required this.authorizeConnectionUseCase,
    required this.connectRepository,
    required this.controlPanelRepository,
  }) {
    setup();
  }

  Timer? _seekDebounceTimer;

  StreamController<int>? _seekDurationUpdatesStreamController;
  StreamController<CurrentSong?>? _currentSongStreamController;
  StreamController<bool>? _togglePlayPauseStreamController;

  @override
  void setup() async {
    // Handle setup action
    final result = await authorizeConnectionUseCase(
      ConnectParameters(
        username: "pat",
        userPasscode: "1234",
        roomId: "569841",
        clientType: "ADMIN",
      ),
    );

    // TODO: TEMPORARY! Will have a separate screen for connection
    var canProceed = false;
    result.fold(
      (error) {
        debugPrint('Error: $error');
      },
      (success) {
        debugPrint('Success: $success');
        connectRepository.connectSocket();
        canProceed = true;
      },
    );

    if (!canProceed) {
      return;
    }
    _seekDurationUpdatesStreamController =
        controlPanelRepository.seekDurationInMillisecondsStreamController();
    _seekDurationUpdatesStreamController?.stream.listen((value) {
      if (isSeeking) {
        return;
      }
      double seconds = value / 1000;
      currentSeekValueNotifier.value = seconds;
    });

    _currentSongStreamController =
        controlPanelRepository.currentSongStreamController();
    _currentSongStreamController?.stream.listen((song) {
      debugPrint('Current song: $song');
      if (song == null) {
        stateNotifier.value = PlayerControlPanelState.inactive();
        return;
      }
      final durationInSeconds = song.durationInSeconds;
      stateNotifier.value = ActiveState(
        title: song.title,
        artist: song.artist,
        thumbnailURL: song.thumbnailURL,
        maxSeekValue: durationInSeconds.toDouble(),
      );
      debugPrint("Duration in seconds: $durationInSeconds");
    });

    _togglePlayPauseStreamController =
        controlPanelRepository.togglePlayPauseStreamController();
    _togglePlayPauseStreamController?.stream.listen((isPlaying) {
      final currentState = stateNotifier.value;
      if (currentState is ActiveState) {
        currentState.isPlayingNotifier.value = isPlaying;
      }
    });
  }

  @override
  void togglePlayPause(bool isPlaying) =>
      controlPanelRepository.togglePlayPause(isPlaying);

  @override
  void nextSong() => controlPanelRepository.skipSong();

  @override
  void seek(double value) {
    super.seek(value);

    _seekDebounceTimer?.cancel();
    _seekDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      // Handle seek action
      debugPrint('Will seek to $value');
      controlPanelRepository.seekDurationFromControl(value.toInt());
    });
  }

  @override
  void setVolume(double value) {
    super.setVolume(value);

    // Handle volume change action
    debugPrint('Setting volume to $value');
  }

  @override
  void dispose() {
    _seekDurationUpdatesStreamController?.close();
    _currentSongStreamController?.close();
    super.dispose();
  }
}
