part of '../adminfeature.dart';

abstract class PlayerControlPanelViewModel extends ChangeNotifier {
  ValueNotifier<PlayerControlPanelState> stateNotifier =
      ValueNotifier(PlayerControlPanelState.inactive());
  ValueNotifier<double> currentSeekValueNotifier = ValueNotifier(0.0);
  ValueNotifier<double> currentVolumeValueNotifier = ValueNotifier(0.5);
  ValueNotifier<PlayerItem?> selectedPlayerItemNotifier = ValueNotifier(null);

  bool isSeeking = false;

  Room get room;

  void updateSelectedPlayerItem(PlayerItem? playerItem) {
    debugPrint('Selected player item: $playerItem');
    selectedPlayerItemNotifier.value = playerItem;
  }

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
  final ConnectRepository connectRepository;
  final ControlPanelSocketRepository controlPanelRepository;
  final AuthorizeConnectionUseCase authorizeConnectionUseCase;

  @override
  final Room room;

  DefaultPlayerControlPanelViewModel({
    required this.connectRepository,
    required this.controlPanelRepository,
    required this.room,
  }) : authorizeConnectionUseCase =
            AuthorizeConnectionUseCase(connectRepository: connectRepository) {
    setup();
  }

  Timer? _seekDebounceTimer;
  Timer? _volumeDebounceTimer;

  StreamController<int>? _seekDurationUpdatesStreamController;
  StreamController<CurrentSong?>? _currentSongStreamController;
  StreamController<bool>? _togglePlayPauseStreamController;

  void setup() async {
    _seekDurationUpdatesStreamController =
        controlPanelRepository.seekDurationInMillisecondsStreamController();
    _seekDurationUpdatesStreamController?.stream.listen((value) {
      if (isSeeking) {
        return;
      }
      debugPrint('Seek value: $value');
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
  void togglePlayPause(bool isPlaying) {
    if (stateNotifier.value is InactiveState) {
      return;
    }
    controlPanelRepository.togglePlayPause(isPlaying);
  }

  @override
  void nextSong() {
    if (stateNotifier.value is InactiveState) {
      return;
    }
    controlPanelRepository.skipSong();
  }

  @override
  void seek(double value) {
    super.seek(value);

    _seekDebounceTimer?.cancel();
    _seekDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      // Handle seek action
      debugPrint('Will seek to $value');

      if (stateNotifier.value is InactiveState) {
        super.seek(0);
        return;
      }
      controlPanelRepository.seekDurationFromControl(value.toInt());
    });
  }

  @override
  void setVolume(double value) {
    super.setVolume(value);

    _volumeDebounceTimer?.cancel();
    _volumeDebounceTimer = Timer(const Duration(milliseconds: 0), () {
      // Handle volume action
      debugPrint('Will set volume to $value');

      if (stateNotifier.value is InactiveState) {
        super.setVolume(0.5);
        return;
      }
      controlPanelRepository.adjustVolumeFromControl(value);
    });
  }

  @override
  void dispose() {
    _seekDurationUpdatesStreamController?.close();
    _currentSongStreamController?.close();
    super.dispose();
  }
}
