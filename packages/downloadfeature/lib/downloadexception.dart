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
}

enum ExceptionType {
  emptyUrl,
  invalidUrl,
  unableToIdentifySong,
}
