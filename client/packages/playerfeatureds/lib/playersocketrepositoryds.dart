part of 'playerfeatureds.dart';

class PlayerSocketRepositoryDS implements PlayerSocketRepository {
  final SingalongSocket socket;
  final SingalongConfiguration configuration;

  PlayerSocketRepositoryDS({
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
        videoURL:
            configuration.buildResourceURL(apiCurrentSong.videoPath).toString(),
      );
      controller.add(currentSong);
    });
    return controller;
  }

  @override
  void seekDurationFromPlayer(int durationInMilliseconds) {
    socket.emitEvent(
        SocketEvent.seekDurationFromPlayer, durationInMilliseconds);
  }

  @override
  StreamController<int> seekDurationFromControlStreamController() {
    final seekUpdatesFromControlStreamController =
        socket.buildSeekDurationFromControlStreamController();
    StreamController<int> controller = StreamController<int>(
      onCancel: () => seekUpdatesFromControlStreamController.close(),
    );
    seekUpdatesFromControlStreamController.stream.listen((duration) {
      controller.add(duration);
    });
    return controller;
  }

  @override
  void skipSong() {
    socket.emitEvent(SocketEvent.skipSong, null);
  }
}
