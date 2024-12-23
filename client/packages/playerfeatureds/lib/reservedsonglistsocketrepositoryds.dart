part of 'playerfeatureds.dart';

class ReservedSongListRepositoryDS implements ReservedSongListSocketRepository {
  final SingalongSocket socket;
  final SingalongConfiguration configuration;

  ReservedSongListRepositoryDS({
    required this.socket,
    required this.configuration,
  });

  @override
  StreamController<List<ReservedSongItem>> get reservedSongsStreamController =>
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
}
