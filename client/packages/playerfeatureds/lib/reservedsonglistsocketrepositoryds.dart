part of 'playerfeatureds.dart';

class ReservedSongListRepositoryDS implements ReservedSongListSocketRepository {
  final SingalongSocket socket;
  final SingalongConfiguration configuration;

  ReservedSongListRepositoryDS({
    required this.socket,
    required this.configuration,
  });

  @override
  StreamController<List<ReservedSongItem>> reservedSongsStreamController() {
    return socket.buildEventStreamController(SocketEvent.reservedSongs,
        (data, controller) {
      final raw = APIReservedSong.fromList(data);
      final reservedSongs = raw
          .map((e) => ReservedSongItem(
                title: e.title,
                artist: e.artist,
                reservedBy: e.reservingUser,
                thumbnailURL:
                    configuration.buildResourceURL(e.thumbnailPath).toString(),
                isPlaying: e.currentPlaying,
              ))
          .toList();
      controller.add(reservedSongs);
    });
    // TODO: Clean this up once confirmed that it works
    final reservedSongsStreamController =
        socket.buildReservedSongsStreamController();
    StreamController<List<ReservedSongItem>> controller =
        StreamController<List<ReservedSongItem>>(
      onCancel: () => reservedSongsStreamController.close(),
    );

    reservedSongsStreamController.stream.listen((event) {
      final reservedSongs = event
          .map(
            (apiReservedSong) => ReservedSongItem(
              title: apiReservedSong.title,
              artist: apiReservedSong.artist,
              reservedBy: apiReservedSong.reservingUser,
              thumbnailURL: configuration
                  .buildResourceURL(apiReservedSong.thumbnailPath)
                  .toString(),
              isPlaying: apiReservedSong.currentPlaying,
            ),
          )
          .toList();
      controller.add(reservedSongs);
    });

    return controller;
  }
}
