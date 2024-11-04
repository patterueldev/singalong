import 'package:connectfeature/connectfeature.dart';
import 'package:downloadfeature/downloadfeature.dart';
import 'package:flutter/material.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:shared/shared.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:songbookfeature/songbookfeature.dart';

class DefaultAppLocalizations
    with
        GenericLocalizationsMixin,
        ConnectLocalizationsMixin,
        SessionLocalizationsMixin,
        SongBookLocalizationsMixin,
        DownloadLocalizationsMixin {}

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

mixin DownloadLocalizationsMixin implements DownloadLocalizations {
  @override
  final songDetailsScreenTitleText = _getLocalizedString(
      (localizations) => localizations.songDetailsScreenTitle);

  @override
  final songTitlePlaceholderText = _getLocalizedString(
      (localizations) => localizations.songTitlePlaceholder);

  @override
  final songArtistPlaceholderText = _getLocalizedString(
      (localizations) => localizations.songArtistPlaceholder);

  @override
  final songLanguagePlaceholderText = _getLocalizedString(
      (localizations) => localizations.songLanguagePlaceholder);

  @override
  final isOffVocalText =
      _getLocalizedString((localizations) => localizations.isOffVocal);

  @override
  final hasLyricsText =
      _getLocalizedString((localizations) => localizations.hasLyrics);

  @override
  final lyricsPlaceholderText =
      _getLocalizedString((localizations) => localizations.lyricsPlaceholder);

  @override
  final downloadOnlyText = _getLocalizedString(
      (localizations) => localizations.downloadOnlyButtonText);

  @override
  final downloadAndReserveText = _getLocalizedString(
      (localizations) => localizations.downloadAndReserveButtonText);

  @override
  final identifySongScreenTitleText = _getLocalizedString(
      (localizations) => localizations.identifySongScreenTitle);

  @override
  final identifySongUrlPlaceholderText = _getLocalizedString(
      (localizations) => localizations.identifySongUrlPlaceholder);

  @override
  final identifySongSubmitButtonText = _getLocalizedString(
      (localizations) => localizations.identifySongSubmitButtonText);

  @override
  final emptyUrl =
      _getLocalizedString((localizations) => localizations.emptyUrl);

  @override
  final invalidUrl =
      _getLocalizedString((localizations) => localizations.invalidUrl);

  @override
  final unableToIdentifySong = _getLocalizedString(
      (localizations) => localizations.unableToIdentifySong);

  @override
  final alreadyExists =
      _getLocalizedString((localizations) => localizations.alreadyExists);

  @override
  final emptySongTitle =
      _getLocalizedString((localizations) => localizations.emptySongTitle);

  @override
  final emptySongArtist =
      _getLocalizedString((localizations) => localizations.emptySongArtist);

  @override
  final emptySongLanguage =
      _getLocalizedString((localizations) => localizations.emptySongLanguage);
}
