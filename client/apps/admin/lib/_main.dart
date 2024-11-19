import 'package:adminfeature/adminfeature.dart';
import 'package:common/common.dart';
import 'package:core/core.dart';
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
    with SongBookLocalizationsMixin {}

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

class DefaultAppAssets with SongBookAssetsMixin {}

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
