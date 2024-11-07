part of 'playerfeatureds.dart';

class ReservedSongListRepositoryDS implements ReservedSongListSocketRepository {
  final SingalongSocket apiClient;
  final SingalongConfiguration configuration;

  ReservedSongListRepositoryDS({
    required this.apiClient,
    required this.configuration,
  });

  @override
  StreamController<List<ReservedSongItem>> reservedSongsStreamController() {
    final reservedSongsStreamController =
        apiClient.buildReservedSongsStreamController();
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
