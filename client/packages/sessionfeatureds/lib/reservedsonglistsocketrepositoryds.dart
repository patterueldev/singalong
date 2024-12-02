part of 'sessionfeatureds.dart';

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
              final apiReservedSongs = APIReservedSong.fromList(data);
              final reservedSongs = apiReservedSongs
                  .map((apiSong) => apiSong.toReservedSongItem(configuration))
                  .toList();
              controller.add(reservedSongs);
            },
          );

  @override
  void requestReservedSongList() {
    socket.emitRoomDataRequestEvent([RoomDataType.reservedSongs]);
  }
}
