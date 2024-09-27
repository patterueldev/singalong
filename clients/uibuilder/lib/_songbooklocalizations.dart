part of 'main.dart';

mixin SongBookLocalizationsMixin implements SongBookLocalizations {
  @override
  final LocalizedString songBookScreenTitle =
      _getLocalizedString((localizations) => localizations.songBookScreenTitle);
  @override
  final LocalizedString searchHint = _getLocalizedString(
      (localizations) => localizations.searchPlaceholderText);
  @override
  final LocalizedString download =
      _getLocalizedString((localizations) => localizations.downloadButtonText);
  @override
  final LocalizedString emptySongBook =
      _getLocalizedString((localizations) => localizations.emptySongBook);

  @override
  LocalizedString songNotFound(String query) {
    return _getLocalizedString(
        (localizations) => localizations.songNotFound(query));
  }
}
