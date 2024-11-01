part of '../songbookfeature.dart';

abstract class FetchSongsUseCase {
  TaskEither<SongBookException, LoadSongsResult> call(
      LoadSongsParameters parameters);
}

class DefaultFetchSongsUseCase implements FetchSongsUseCase {
  final SongRepository songRepository;

  DefaultFetchSongsUseCase({
    required this.songRepository,
  });

  @override
  TaskEither<SongBookException, LoadSongsResult> call(
          LoadSongsParameters parameters) =>
      TaskEither.tryCatch(() async {
        return await songRepository.loadSongs(parameters);
        // // Simulate fetching data
        // await Future.delayed(const Duration(seconds: 2));
        // var songList = [
        //   SongItem(
        //     title: 'Song 1',
        //     artist: 'Artist 1',
        //     imageURL: 'https://via.placeholder.com/150',
        //     alreadyPlayed: false,
        //   ),
        //   SongItem(
        //     title: 'Song 2',
        //     artist: 'Artist 2',
        //     imageURL: 'https://via.placeholder.com/150',
        //     alreadyPlayed: true,
        //   ),
        //   SongItem(
        //     title: 'Song 3',
        //     artist: 'Artist 3',
        //     imageURL: 'https://via.placeholder.com/150',
        //     alreadyPlayed: false,
        //   ),
        // ];
        //
        // final String? query =
        //     searchQuery.trim().isNotEmpty ? searchQuery : null;
        // if (query != null) {
        //   songList = songList
        //       .where((song) =>
        //           song.title.toLowerCase().contains(query.toLowerCase()) ||
        //           song.artist.toLowerCase().contains(query.toLowerCase()))
        //       .toList();
        // }
        // songList.clear();
        // return FetchSongResult(songList, null);
      }, (e, s) {
        if (e is SongBookException) {
          return e;
        }
        return SongBookException('Failed to fetch songs');
      });
}
