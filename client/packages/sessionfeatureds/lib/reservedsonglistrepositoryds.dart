part of 'sessionfeatureds.dart';

class ReservedSongListRepositoryDS implements ReservedSongListRepository {
  final SingalongAPIClient apiClient;

  ReservedSongListRepositoryDS({
    required this.apiClient,
  });

  @override
  Stream<List<ReservedSongItem>> listenToSongListUpdates() async* {
    await for (final apiSongs in apiClient.listenReservedSongs()) {
      debugPrint("API Songs: $apiSongs");
      final reservedSongs = apiSongs
          .map((apiSong) => ReservedSongItem(
                id: apiSong.id,
                songId: apiSong.songId,
                title: apiSong.title,
                artist: apiSong.artist,
                thumbnailURL: apiClient.resourceURL(apiSong.thumbnailPath),
                reservingUser: apiSong.reservingUser,
                currentPlaying: apiSong.currentPlaying,
              ))
          .toList();
      yield reservedSongs;
    }
  }
}
