part of 'adminfeatureds.dart';

class ControlPanelRepositoryDS implements ControlPanelSocketRepository {
  final SingalongSocket socket;
  final SingalongConfiguration configuration;

  ControlPanelRepositoryDS({
    required this.socket,
    required this.configuration,
  });

  @override
  StreamController<CurrentSong?> currentSongStreamController() {
    final currentSongStreamController =
        socket.buildCurrentSongStreamController();
    StreamController<CurrentSong?> controller = StreamController<CurrentSong?>(
      onCancel: () => currentSongStreamController.close(),
    );

    currentSongStreamController.stream.listen((apiCurrentSong) {
      if (apiCurrentSong == null) {
        controller.add(null);
        return;
      }
      final currentSong = CurrentSong(
        id: apiCurrentSong.id,
        title: apiCurrentSong.title,
        artist: apiCurrentSong.artist,
        thumbnailURL: configuration
            .buildResourceURL(apiCurrentSong.thumbnailPath)
            .toString(),
        reservingUser: apiCurrentSong.reservingUser,
        durationInSeconds: apiCurrentSong.durationInSeconds,
        videoURL:
            configuration.buildResourceURL(apiCurrentSong.videoPath).toString(),
      );
      controller.add(currentSong);
    });
    return controller;
  }

  @override
  StreamController<int> seekDurationInMillisecondsStreamController() {
    final seekDurationInMillisecondsStreamController =
        socket.buildSeekDurationFromPlayerStreamController();
    StreamController<int> controller = StreamController<int>(
      onCancel: () => seekDurationInMillisecondsStreamController.close(),
    );

    seekDurationInMillisecondsStreamController.stream.listen((duration) {
      controller.add(duration);
    });
    return controller;
  }

  @override
  StreamController<bool> togglePlayPauseStreamController() {
    return socket.buildEventStreamController(SocketEvent.togglePlayPause,
        (data, controller) {
      controller.add(data as bool);
    });
  }

  @override
  void seekDurationFromControl(int durationInSeconds) {
    return socket.emitEvent(
        SocketEvent.seekDurationFromControl, durationInSeconds);
  }

  @override
  void skipSong() {
    return socket.emitEvent(SocketEvent.skipSong, null);
  }

  @override
  void togglePlayPause(bool isPlaying) {
    debugPrint('Toggling play/pause');
    return socket.emitEvent(SocketEvent.togglePlayPause, isPlaying);
  }
}
