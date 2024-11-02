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
      }, (e, s) {
        if (e is SongBookException) {
          return e;
        }
        return SongBookException('Failed to fetch songs');
      });
}
