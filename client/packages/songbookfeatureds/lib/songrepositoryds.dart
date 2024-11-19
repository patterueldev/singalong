part of 'songbookfeatureds.dart';

class SongRepositoryDS implements SongRepository {
  final SingalongAPI api;
  final SingalongConfiguration configuration;

  SongRepositoryDS({
    required this.api,
    required this.configuration,
  });

  @override
  Future<LoadSongsResult> loadSongs(LoadSongsParameters parameters) async {
    try {
      debugPrint(
          'SongRepositoryDS: Fetching songs with parameters: $parameters');
      final result = await api.loadSongs(
        APILoadSongsParameters(
          keyword: parameters.keyword,
          limit: parameters.limit,
          nextOffset: parameters.nextOffset,
          nextCursor: parameters.nextCursor,
          nextPage: parameters.nextPage,
          roomId: parameters.roomId,
        ),
      );
      final apiSongs = result.items;
      final songs = apiSongs
          .map((apiSong) => SongbookItem(
                id: apiSong.id,
                title: apiSong.title,
                artist: apiSong.artist,
                thumbnailURL: configuration
                    .buildResourceURL(apiSong.thumbnailPath)
                    .toString(),
                alreadyPlayed: false,
              ))
          .toList();
      return LoadSongsResult(
        songs,
        nextOffset: result.nextOffset,
        nextCursor: result.nextCursor,
        nextPage: result.nextPage,
      );
    } catch (e) {
      debugPrint("Error: $e");
      rethrow;
    }
  }

  @override
  Future<void> reserveSong(SongbookItem song) async {
    try {
      debugPrint('SongRepositoryDS: Reserving song: $song');
      final parameters = APIReserveSongParameters(songId: song.id);
      return await api.reserveSong(parameters);
    } catch (e) {
      throw e;
    }
  }
}
