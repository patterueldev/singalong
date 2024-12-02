part of 'adminfeatureds.dart';

class ControlPanelRepositoryDS implements ControlPanelSocketRepository {
  final SingalongSocket socket;
  final SingalongConfiguration configuration;

  ControlPanelRepositoryDS({
    required this.socket,
    required this.configuration,
  });

  @override
  void requestControlPanelData() {
    final dataTypes = [
      RoomDataType.currentSong,
      RoomDataType.assignedPlayerInRoom
    ];
    socket.emitRoomDataRequestEvent(dataTypes);
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
            lyrics: raw.lyrics,
            reservingUser: raw.reservingUser,
            durationInSeconds: raw.durationInSeconds,
            videoURL: configuration.buildResourceURL(raw.videoPath).toString(),
            volume: raw.volume,
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
  StreamController<PlayerItem?> get selectedPlayerItemStreamController =>
      socket.buildRoomEventStreamController(
        SocketEvent.playerAssigned,
        (data, controller) {
          debugPrint('Selected player item: $data');
          if (data == null) {
            controller.add(null);
            return;
          }
          final raw = APIPlayerItem.fromJson(data);
          final playerItem = PlayerItem(
            id: raw.id,
            name: raw.name,
            isIdle: raw.isIdle,
          );
          controller.add(playerItem);
        },
      );

  @override
  void seekDuration({required int durationInSeconds}) {
    socket.emitRoomCommandEvent(RoomCommand.seekDurationFromControl(
        durationInSeconds: durationInSeconds));
    return socket.emitRoomEvent(SocketEvent.seekDuration, durationInSeconds);
  }

  @override
  void skipSong({required bool completed}) {
    socket.emitRoomCommandEvent(RoomCommand.skipSong(completed));
  }

  @override
  void togglePlayPause(bool isPlaying) {
    debugPrint('Toggling play/pause');
    // return socket.emitEvent(SocketEvent.togglePlayPause, isPlaying);
    socket.emitRoomCommandEvent(RoomCommand.togglePlayPause(isPlaying));
  }

  @override
  void adjustVolumeFromControl(double volume) {
    socket.emitRoomCommandEvent(RoomCommand.adjustVolume(volume));
  }
}
