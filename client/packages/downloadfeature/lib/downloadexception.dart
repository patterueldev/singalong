part of '../downloadfeature.dart';

class DownloadException extends GenericException {
  final ExceptionType type;
  const DownloadException._(this.type) : super();

  @override
  LocalizedString localizedFrom(GenericLocalizations localizations) {
    final downloadLocalizations = localizations as DownloadLocalizations;
    switch (type) {
      case ExceptionType.emptyUrl:
        return downloadLocalizations.emptyUrl;
      case ExceptionType.invalidUrl:
        return downloadLocalizations.invalidUrl;
      case ExceptionType.unableToIdentifySong:
        return downloadLocalizations.unableToIdentifySong;
      case ExceptionType.alreadyExists:
        return downloadLocalizations.alreadyExists;
      case ExceptionType.emptySongTitle:
        return downloadLocalizations.emptySongTitle;
      case ExceptionType.emptySongArtist:
        return downloadLocalizations.emptySongArtist;
      case ExceptionType.emptySongLanguage:
        return downloadLocalizations.emptySongLanguage;
      default:
        return super.localizedFrom(localizations);
    }
  }

  factory DownloadException.emptyUrl() =>
      const DownloadException._(ExceptionType.emptyUrl);
  factory DownloadException.invalidUrl() =>
      const DownloadException._(ExceptionType.invalidUrl);
  factory DownloadException.unableToIdentifySong() =>
      const DownloadException._(ExceptionType.unableToIdentifySong);
  factory DownloadException.alreadyExists() =>
      const DownloadException._(ExceptionType.alreadyExists);

  factory DownloadException.emptySongTitle() =>
      const DownloadException._(ExceptionType.emptySongTitle);
  factory DownloadException.emptySongArtist() =>
      const DownloadException._(ExceptionType.emptySongArtist);
  factory DownloadException.emptySongLanguage() =>
      const DownloadException._(ExceptionType.emptySongLanguage);
}

enum ExceptionType {
  emptyUrl,
  invalidUrl,
  unableToIdentifySong,
  alreadyExists,

  emptySongTitle,
  emptySongArtist,
  emptySongLanguage,
}
