part of 'songbookfeature.dart';

class FetchSongResult {
  final List<SongItem> songs;
  final Object? next;

  FetchSongResult(this.songs, this.next);
}

abstract class FetchSongsUseCase {
  TaskEither<SongBookException, FetchSongResult> call({
    required String searchQuery,
    int limit = 20,
    Object? next,
  });
}

class DefaultFetchSongsUseCase implements FetchSongsUseCase {
  DefaultFetchSongsUseCase();

  @override
  TaskEither<SongBookException, FetchSongResult> call({
    required String searchQuery,
    int limit = 20,
    Object? next,
  }) =>
      TaskEither.tryCatch(() async {
        // Simulate fetching data
        await Future.delayed(const Duration(seconds: 2));
        var songList = [
          SongItem(
            title: 'Song 1',
            artist: 'Artist 1',
            imageURL: 'https://via.placeholder.com/150',
            alreadyPlayed: false,
          ),
          SongItem(
            title: 'Song 2',
            artist: 'Artist 2',
            imageURL: 'https://via.placeholder.com/150',
            alreadyPlayed: true,
          ),
          SongItem(
            title: 'Song 3',
            artist: 'Artist 3',
            imageURL: 'https://via.placeholder.com/150',
            alreadyPlayed: false,
          ),
        ];

        final String? query =
            searchQuery.trim().isNotEmpty ? searchQuery : null;
        if (query != null) {
          songList = songList
              .where((song) =>
                  song.title.toLowerCase().contains(query.toLowerCase()) ||
                  song.artist.toLowerCase().contains(query.toLowerCase()))
              .toList();
        }
        songList.clear();
        return FetchSongResult(songList, null);
      }, (e, s) {
        if (e is SongBookException) {
          return e;
        }
        return SongBookException('Failed to fetch songs');
      });
}
