part of '../adminfeature.dart';

abstract class PlayerControlPanelViewModel extends ChangeNotifier {
  ValueNotifier<PlayerControlPanelState> stateNotifier =
      ValueNotifier(PlayerControlPanelState.inactive());
  ValueNotifier<double> currentSeekValueNotifier = ValueNotifier(0.0);
  ValueNotifier<double> currentVolumeValueNotifier = ValueNotifier(0.5);
  bool isSeeking = false;

  void setup();
  void pause();
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
  final ControlPanelRepository controlPanelRepository;

  DefaultPlayerControlPanelViewModel({
    required this.authorizeConnectionUseCase,
    required this.connectRepository,
    required this.controlPanelRepository,
  }) {
    setup();
  }

  StreamSubscription? _seekDurationUpdatesListener;

  Timer? _seekDebounceTimer;

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

    controlPanelRepository.listenToCurrentSongUpdates().listen((song) {
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

    _seekDurationUpdatesListener = controlPanelRepository
        .listenSeekDurationInMillisecondsUpdates()
        .listen((value) {
      if (isSeeking) {
        return;
      }
      double seconds = value / 1000;
      debugPrint('Seek duration in seconds: $seconds');
      currentSeekValueNotifier.value = seconds;
    });
  }

  @override
  void pause() {
    // Handle pause action
  }

  @override
  void nextSong() {
    // Handle next song action
  }

  @override
  void seek(double value) {
    super.seek(value);

    _seekDebounceTimer?.cancel();
    _seekDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      // Handle seek action
      debugPrint('Will seek to $value');
      controlPanelRepository.seekToDuration(value.toInt());
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
    _seekDurationUpdatesListener?.cancel();
    super.dispose();
  }
}
