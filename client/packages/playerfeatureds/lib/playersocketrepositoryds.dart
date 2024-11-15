part of 'playerfeatureds.dart';

class PlayerSocketRepositoryDS implements PlayerSocketRepository {
  final SingalongSocket socket;
  final SingalongConfiguration configuration;

  PlayerSocketRepositoryDS({
    required this.socket,
    required this.configuration,
  });

  @override
  Future<void> registerIdlePlayer(String playerId, String deviceId) async {
    await socket.connectIdleSocket(playerId, deviceId);
  }

  @override
  void requestPlayerData() {
    socket.emitDataRequestEvent([
      RoomDataType.reservedSongs,
      RoomDataType.currentSong,
    ]);
  }

  @override
  StreamController<CurrentSong?> get currentSongStreamController =>
      socket.buildRoomEventStreamController(SocketEvent.currentSong,
          (data, controller) {
        if (data == null) {
          controller.add(null);
          return;
        }
        final apiCurrentSong = APICurrentSong.fromJson(data);
        final currentSong = CurrentSong(
          id: apiCurrentSong.id,
          title: apiCurrentSong.title,
          artist: apiCurrentSong.artist,
          thumbnailURL: configuration
              .buildResourceURL(apiCurrentSong.thumbnailPath)
              .toString(),
          reservingUser: apiCurrentSong.reservingUser,
          videoURL: configuration
              .buildResourceURL(apiCurrentSong.videoPath)
              .toString(),
        );
        controller.add(currentSong);
      });

  @override
  void durationUpdate({required int durationInMilliseconds}) {
    socket.emitCommandEvent(RoomCommand.durationUpdate(
        durationInMilliseconds: durationInMilliseconds));
  }

  @override
  StreamController<int> get seekDurationFromControlStreamController =>
      socket.buildRoomEventStreamController(
        SocketEvent.seekDuration,
        (data, controller) {
          final seekValue = data as int;
          controller.add(seekValue);
        },
      );

  @override
  void skipSong() {
    socket.emitCommandEvent(RoomCommand.skipSong());
  }

  @override
  StreamController<String> get roomAssignedStreamController =>
      socket.buildIdleEventStreamController(
        SocketEvent.roomAssigned,
        (data, controller) {
          debugPrint("Player - Room assigned: $data");
          controller.add(data as String);
        },
      );

  @override
  StreamController<bool> get togglePlayPauseStreamController =>
      socket.buildRoomEventStreamController(SocketEvent.togglePlayPause,
          (data, controller) {
        debugPrint("Player - Toggle play/pause: $data");
        controller.add(data as bool);
      });

  @override
  StreamController<double> get volumeStreamController =>
      socket.buildRoomEventStreamController(SocketEvent.adjustVolumeFromControl,
          (data, controller) {
        debugPrint("Player - Volume: $data");
        controller.add(data as double);
      });
}
