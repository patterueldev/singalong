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
                  .map((apiSong) => ReservedSongItem(
                        id: apiSong.id,
                        songId: apiSong.songId,
                        title: apiSong.title,
                        artist: apiSong.artist,
                        thumbnailURL: configuration
                            .buildResourceURL(apiSong.thumbnailPath)
                            .toString(),
                        reservingUser: apiSong.reservingUser,
                        currentPlaying: apiSong.currentPlaying,
                      ))
                  .toList();
              controller.add(reservedSongs);
            },
          );

  @override
  void requestReservedSongList() {
    socket.emitRoomDataRequestEvent([RoomDataType.reservedSongs]);
  }
}
