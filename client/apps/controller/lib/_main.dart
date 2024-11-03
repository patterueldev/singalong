import 'package:connectfeature/connectfeature.dart';
import 'package:connectfeatureds/connectfeatureds.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:sessionfeatureds/sessionfeatureds.dart';
import 'package:singalong_api_client/singalong_api_client.dart';
import 'package:songbookfeature/songbookfeature.dart';
import 'package:songbookfeatureds/songbookfeatureds.dart';

import 'assets/app_assets.dart';
import 'localizations/app_localizations.dart';

MultiProvider buildProviders() {
  final singalongAPIClientProvider = SingalongAPIClientProvider();
  final connectFeatureDSProvider = ConnectFeatureDSProvider();
  final sessionFeatureDSProvider = SessionFeatureDSProvider();
  final songBookFeatureProvider = SongBookFeatureDSProvider();
  final localizations = DefaultAppLocalizations();
  final assets = DefaultAppAssets();

  return MultiProvider(
    providers: [
      Provider<ConnectAssets>.value(value: assets),
      Provider<ConnectLocalizations>.value(value: localizations),
      Provider<SessionLocalizations>.value(value: localizations),
      Provider<SongBookAssets>.value(value: assets),
      Provider<SongBookLocalizations>.value(value: localizations),
      singalongAPIClientProvider.providers,
      connectFeatureDSProvider.providers,
      sessionFeatureDSProvider.providers,
      songBookFeatureProvider.providers,
    ],
  );
}
