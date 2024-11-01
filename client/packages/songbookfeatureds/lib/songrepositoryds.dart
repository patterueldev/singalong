part of 'songbookfeatureds.dart';

class SongRepositoryDS implements SongRepository {
  final SingalongAPIClient apiClient;

  SongRepositoryDS({
    required this.apiClient,
  });

  @override
  Future<LoadSongsResult> loadSongs(LoadSongsParameters parameters) async {
    try {
      debugPrint(
          'SongRepositoryDS: Fetching songs with parameters: $parameters');
      final result = await apiClient.loadSongs(
        APILoadSongsParameters(
          keyword: parameters.keyword,
          limit: parameters.limit,
          nextOffset: parameters.nextOffset,
          nextCursor: parameters.nextCursor,
          nextPage: parameters.nextPage,
        ),
      );
      final apiSongs = result.items;
      final songs = apiSongs
          .map((apiSong) => SongItem(
                id: apiSong.id,
                title: apiSong.title,
                artist: apiSong.artist,
                thumbnailURL: apiClient.resourceURL(apiSong.thumbnailPath),
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
      throw e;
    }
  }
}
