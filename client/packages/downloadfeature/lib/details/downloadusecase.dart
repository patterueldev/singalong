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
          validate(details);
          await identifiedSongRepository.saveSong(details, reserve: reserve);
          return unit;
        },
        (e, s) {
          if (e is GenericException) return e;
          return GenericException.unhandled(e);
        },
      );

  void validate(IdentifiedSongDetails details) {
    if (details.songTitle.trim().isEmpty) {
      throw DownloadException.emptySongTitle();
    }

    if (details.songArtist.trim().isEmpty) {
      throw DownloadException.emptySongArtist();
    }

    if (details.songLanguage.trim().isEmpty) {
      throw DownloadException.emptySongLanguage();
    }
  }
}
