part of 'main.dart';

class DefaultAppLocalizations
    with
        GenericLocalizationsMixin,
        ConnectLocalizationsMixin,
        SessionLocalizationsMixin
    implements ConnectLocalizations, SessionLocalizations {}

LocalizedString _getLocalizedString(
        String Function(AppLocalizations) getString) =>
    LocalizedString((context) {
      final localizations = AppLocalizations.of(context);
      if (localizations == null) {
        throw FlutterError(
            'AppLocalizations not found in the widget tree. Ensure that the MaterialApp has the localizationsDelegates and supportedLocales properly set.');
      }
      return getString(localizations);
    });

mixin GenericLocalizationsMixin implements GenericLocalizations {
  @override
  final unknownError = _getLocalizedString((l) => l.unknownError);
}

mixin ConnectLocalizationsMixin implements ConnectLocalizations {
  @override
  final screenTitleText =
      _getLocalizedString((localizations) => localizations.screenTitleText);

  @override
  final connectButtonText =
      _getLocalizedString((localizations) => localizations.connectButtonText);

  @override
  final clearButtonText =
      _getLocalizedString((localizations) => localizations.clearButtonText);

  @override
  final namePlaceholderText =
      _getLocalizedString((localizations) => localizations.namePlaceholderText);

  @override
  final sessionIdPlaceholderText = _getLocalizedString(
      (localizations) => localizations.sessionIdPlaceholderText);

  @override
  final connectionSuccess =
      _getLocalizedString((localizations) => localizations.connectionSuccess);

  @override
  final emptyName =
      _getLocalizedString((localizations) => localizations.emptyName);

  @override
  final emptySessionId =
      _getLocalizedString((localizations) => localizations.emptySessionId);

  @override
  LocalizedString unhandled(String message) {
    return _getLocalizedString(
        (localizations) => localizations.unhandled(message));
  }

  @override
  LocalizedString invalidName(String name) {
    return _getLocalizedString(
        (localizations) => localizations.invalidName(name));
  }

  @override
  LocalizedString invalidSessionId(String sessionId) {
    return _getLocalizedString(
        (localizations) => localizations.invalidSessionId(sessionId));
  }
}
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
}
