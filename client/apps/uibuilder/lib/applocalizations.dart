part of 'main.dart';

class DefaultAppLocalizations
    with
        GenericLocalizationsMixin,
        ConnectLocalizationsMixin,
        SessionLocalizationsMixin,
        SongBookLocalizationsMixin {}

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
