part of 'adminfeatureds.dart';

class ReservedSongListSocketRepositoryDS
    implements ReservedSongListSocketRepository {
  final SingalongSocket socket;
  final SingalongConfiguration configuration;

  ReservedSongListSocketRepositoryDS({
    required this.socket,
    required this.configuration,
  });

  @override
  StreamController<List<ReservedSongItem>>
      get reservedSongListStreamController =>
          socket.buildRoomEventStreamController(
            SocketEvent.reservedSongs,
            (data, controller) {
              final raw = APIReservedSong.fromList(data);
              final reservedSongs = raw
                  .map(
                    (e) => e.toReservedSongItem(configuration),
                  )
                  .toList();
              controller.add(reservedSongs);
            },
          );

  @override
  void requestReservedSongList() {
    socket.emitRoomDataRequestEvent([RoomDataType.reservedSongs]);
  }
}
