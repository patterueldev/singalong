part of '../downloadfeature.dart';

abstract class IdentifySongUrlUseCase {
  TaskEither<GenericException, IdentifiedSongDetails> call(String url);
}

class DefaultIdentifySongUrlUseCase implements IdentifySongUrlUseCase {
  final SongIdentifierRepository songIdentifierRepository;

  DefaultIdentifySongUrlUseCase({
    required this.songIdentifierRepository,
  });

  @override
  TaskEither<GenericException, IdentifiedSongDetails> call(String url) =>
      TaskEither.tryCatch(() async {
        // validate if the url is empty
        if (url.isEmpty) {
          throw DownloadException.emptyUrl();
        }

        if (!isValidUrl(url)) {
          throw DownloadException.invalidUrl();
        }

        final result = await songIdentifierRepository.identifySongUrl(url);
        if (result.alreadyExists) {
          throw DownloadException.alreadyExists();
        }
        return result;
      }, (e, s) {
        if (e is GenericException) {
          return e;
        }
        return GenericException.unhandled(e);
      });

  bool isValidUrl(String url) {
    Uri? uri = Uri.tryParse(url);
    return uri != null && (uri.hasScheme && uri.hasAuthority);
  }
}
