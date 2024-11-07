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
  StreamController<List<ReservedSongItem>> reservedSongListStreamController() {
    final reservedSongsStreamController =
        socket.buildReservedSongsStreamController();
    StreamController<List<ReservedSongItem>> controller =
        StreamController<List<ReservedSongItem>>(
      onCancel: () => reservedSongsStreamController.close(),
    );

    reservedSongsStreamController.stream.listen((apiSongs) {
      final reservedSongs = apiSongs
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
    });
    return controller;
  }
}
