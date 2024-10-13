import 'package:connectfeature/connectfeature.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DefaultAppLocalizations
    with GenericLocalizationsMixin, ConnectLocalizationsMixin {}

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
