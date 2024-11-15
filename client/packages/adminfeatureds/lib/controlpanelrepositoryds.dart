part of 'adminfeatureds.dart';

class ControlPanelRepositoryDS implements ControlPanelSocketRepository {
  final SingalongSocket socket;
  final SingalongConfiguration configuration;

  ControlPanelRepositoryDS({
    required this.socket,
    required this.configuration,
  });

  @override
  void requestCurrentSong() {
    final dataTypes = [RoomDataType.currentSong];
    socket.emitDataRequestEvent(dataTypes);
  }

  @override
  StreamController<CurrentSong?> get currentSongStreamController =>
      socket.buildRoomEventStreamController(
        SocketEvent.currentSong,
        (data, controller) {
          if (data == null) {
            controller.add(null);
            return;
          }
          final raw = APICurrentSong.fromJson(data);
          final currentSong = CurrentSong(
            id: raw.id,
            title: raw.title,
            artist: raw.artist,
            thumbnailURL:
                configuration.buildResourceURL(raw.thumbnailPath).toString(),
            reservingUser: raw.reservingUser,
            durationInSeconds: raw.durationInSeconds,
            videoURL: configuration.buildResourceURL(raw.videoPath).toString(),
          );
          controller.add(currentSong);
        },
      );

  @override
  StreamController<int> get durationUpdateInMillisecondsStreamController =>
      socket.buildRoomEventStreamController(
        SocketEvent.durationUpdate,
        (milliseconds, controller) {
          controller.add(milliseconds as int);
        },
      );

  @override
  StreamController<bool> get togglePlayPauseStreamController =>
      socket.buildRoomEventStreamController(
        SocketEvent.togglePlayPause,
        (data, controller) {
          controller.add(data as bool);
        },
      );

  @override
  void seekDuration({required int durationInSeconds}) {
    socket.emitCommandEvent(RoomCommand.seekDurationFromControl(
        durationInSeconds: durationInSeconds));
    return socket.emitEvent(SocketEvent.seekDuration, durationInSeconds);
  }

  @override
  void skipSong() {
    socket.emitCommandEvent(RoomCommand.skipSong());
  }

  @override
  void togglePlayPause(bool isPlaying) {
    debugPrint('Toggling play/pause');
    // return socket.emitEvent(SocketEvent.togglePlayPause, isPlaying);
    socket.emitCommandEvent(RoomCommand.togglePlayPause(isPlaying));
  }

  @override
  void adjustVolumeFromControl(double volume) {
    socket.emitCommandEvent(RoomCommand.adjustVolume(volume));
  }
}
