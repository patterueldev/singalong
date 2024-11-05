part of '../downloadfeature.dart';

abstract class SearchDownloadableSongUseCase {
  TaskEither<GenericException, List<DownloadableItem>> call(String query);
}

class DefaultSearchDownloadableSongUseCase
    implements SearchDownloadableSongUseCase {
  final SongIdentifierRepository identifiedSongRepository;

  DefaultSearchDownloadableSongUseCase({
    required this.identifiedSongRepository,
  });

  @override
  TaskEither<GenericException, List<DownloadableItem>> call(String query) =>
      TaskEither.tryCatch(
        () async {
          final result =
              await identifiedSongRepository.searchDownloadableSong(query);
          return result;
        },
        (e, s) {
          if (e is DownloadException) {
            return e;
          }

          return GenericException.unhandled(e);
        },
      );
}
