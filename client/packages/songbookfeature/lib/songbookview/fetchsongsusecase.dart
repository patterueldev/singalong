part of '../songbookfeature.dart';

abstract class FetchSongsUseCase {
  TaskEither<GenericException, LoadSongsResult> call(
      LoadSongsParameters parameters);
}

class DefaultFetchSongsUseCase implements FetchSongsUseCase {
  final SongRepository songRepository;

  DefaultFetchSongsUseCase({
    required this.songRepository,
  });

  @override
  TaskEither<GenericException, LoadSongsResult> call(
          LoadSongsParameters parameters) =>
      TaskEither.tryCatch(() async {
        return await songRepository.loadSongs(parameters);
      }, (e, s) {
        if (e is GenericException) {
          return e;
        }
        return GenericException.unhandled(e);
      });
}
