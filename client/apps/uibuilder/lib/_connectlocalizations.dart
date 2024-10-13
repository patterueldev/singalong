part of 'main.dart';

mixin ConnectLocalizationsMixin implements ConnectLocalizations {
  @override
  final connectScreenTitleText =
      _getLocalizedString((localizations) => localizations.connectScreenTitle);

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
