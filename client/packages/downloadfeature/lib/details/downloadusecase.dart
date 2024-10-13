part of '../downloadfeature.dart';

abstract class DownloadUseCase {
  TaskEither<GenericException, Unit> downloadSong(
    IdentifiedSongDetails details, {
    required bool reserve,
  });
}

class DefaultDownloadUseCase implements DownloadUseCase {
  final SongIdentifierRepository identifiedSongRepository;
  DefaultDownloadUseCase({
    required this.identifiedSongRepository,
  });

  @override
  TaskEither<GenericException, Unit> downloadSong(
    IdentifiedSongDetails details, {
    required bool reserve,
  }) =>
      TaskEither.tryCatch(
        () async {
          debugPrint('Downloading song: ${details.songTitle}');
          debugPrint('Reserve: $reserve');
          await Future.delayed(const Duration(seconds: 2));
          return unit;
        },
        (e, s) {
          if (e is GenericException) return e;
          return GenericException.unhandled(e);
        },
      );
}
