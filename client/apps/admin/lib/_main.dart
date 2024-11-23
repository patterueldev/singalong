import 'package:adminfeature/adminfeature.dart';
import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:downloadfeature/downloadfeature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:songbookfeature/songbookfeature.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import 'gen/assets.gen.dart';

part 'appcoordinator.dart';
part 'api_configuration.dart';
part 'app/admin_app.dart';
part 'app/admin_app_viewmodel.dart';
part 'master/master_view.dart';
part 'master/master_viewmodel.dart';

class DefaultAppLocalizations extends AdminLocalizations
    with SongBookLocalizationsMixin, DownloadLocalizationsMixin {}

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

mixin SongBookLocalizationsMixin implements SongBookLocalizations {
  @override
  final LocalizedString songBookScreenTitle =
      _getLocalizedString((localizations) => localizations.songBookScreenTitle);
  @override
  final LocalizedString searchHint = _getLocalizedString(
      (localizations) => localizations.searchPlaceholderText);
  @override
  final LocalizedString search =
      _getLocalizedString((localizations) => localizations.searchButtonText);
  @override
  final LocalizedString download =
      _getLocalizedString((localizations) => localizations.downloadButtonText);
  @override
  final LocalizedString emptySongBook =
      _getLocalizedString((localizations) => localizations.emptySongBook);

  @override
  final isUrlPromptTitle =
      _getLocalizedString((localizations) => localizations.isUrlPromptTitle);

  @override
  final isUrlPromptMessage =
      _getLocalizedString((localizations) => localizations.isUrlPromptMessage);

  @override
  final continueSearchButtonText = _getLocalizedString(
      (localizations) => localizations.continueSearchButtonText);

  @override
  final continueIdentifyButtonText = _getLocalizedString(
      (localizations) => localizations.continueIdentifyButtonText);

  @override
  LocalizedString songNotFound(String query) {
    return _getLocalizedString(
        (localizations) => localizations.songNotFound(query));
  }

  @override
  LocalizedString urlDetected(String url) {
    return _getLocalizedString(
        (localizations) => localizations.urlDetected(url));
  }
}

class DefaultAppAssets with SongBookAssetsMixin, DownloadAssetsMixin {}

mixin SongBookAssetsMixin implements SongBookAssets {
  @override
  final errorBannerImage = AssetSource(
    Assets.images.gakkariTameikiWoman.path,
  );

  @override
  final identifySongBannerImage = AssetSource(
    Assets.images.magnifier4Woman.path,
  );
}

mixin DownloadAssetsMixin implements DownloadAssets {
  @override
  final identifySongBannerImage = AssetSource(
    Assets.images.magnifier4Woman.path,
  );
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

  @override
  final searchByURL =
      _getLocalizedString((localizations) => localizations.searchByURL);

  @override
  final enterSearchKeyword =
      _getLocalizedString((localizations) => localizations.enterSearchKeyword);

  @override
  LocalizedString itemNotFound(String item) =>
      _getLocalizedString((localizations) => localizations.itemNotFound(item));
}
