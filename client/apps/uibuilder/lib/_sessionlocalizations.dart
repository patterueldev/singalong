part of 'main.dart';

mixin SessionLocalizationsMixin implements SessionLocalizations {
  @override
  final LocalizedString disconnectButtonText = _getLocalizedString(
      (localizations) => localizations.disconnectButtonText);

  @override
  final LocalizedString cancelButtonText =
      _getLocalizedString((localizations) => localizations.cancelButtonText);

  @override
  final LocalizedString skipButtonText =
      _getLocalizedString((localizations) => localizations.skipButtonText);

  @override
  final LocalizedString pauseButtonText =
      _getLocalizedString((localizations) => localizations.pauseButtonText);

  @override
  final LocalizedString playNextButtonText =
      _getLocalizedString((localizations) => localizations.playNextButtonText);

  @override
  LocalizedString reservedByText(String name) {
    return _getLocalizedString(
        (localizations) => localizations.reservedByText(name));
  }

  @override
  final LocalizedString skipSongTitle =
      _getLocalizedString((localizations) => localizations.skipSongTitle);

  @override
  final LocalizedString skipSongMessage =
      _getLocalizedString((localizations) => localizations.skipSongMessage);

  @override
  final LocalizedString skipSongActionText =
      _getLocalizedString((localizations) => localizations.skipSongActionText);

  @override
  final LocalizedString cancelSongTitle =
      _getLocalizedString((localizations) => localizations.cancelSongTitle);

  @override
  final LocalizedString cancelSongMessage =
      _getLocalizedString((localizations) => localizations.cancelSongMessage);

  @override
  final LocalizedString cancelSongActionText = _getLocalizedString(
      (localizations) => localizations.cancelSongActionText);

  @override
  LocalizedString get lyricsLabelText =>
      _getLocalizedString((localizations) => localizations.lyricsLabelText);

  @override
  LocalizedString get noLyricsText =>
      _getLocalizedString((localizations) => localizations.lyricsNotAvailable);
}
