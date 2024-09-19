import 'dart:math';

import 'package:connectfeature/connectfeature.dart';
import 'package:downloadfeature/downloadfeature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared/shared.dart';
import 'package:songbookfeature/songbookfeature.dart';
import 'package:uibuilder/gen/assets.gen.dart';

part 'applocalizations.dart';
part 'appcoordinator.dart';
part 'appassets.dart';
part '_genericlocalizations.dart';
part '_connectlocalizations.dart';
part '_sessionlocalizations.dart';
part '_songbooklocalizations.dart';
part 'ui/navigatoritem.dart';
part 'ui/previewerviewmodel.dart';
part 'ui/previewerview.dart';
part 'ui/temporary_screen_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final connectFeatureProvider = ConnectFeatureProvider();
    final sessionFeatureProvider = SessionFeatureProvider();
    final songBookFeatureProvider = SongBookFeatureProvider();
    final downloadFeatureProvider = DownloadFeatureProvider();
    final localizations = DefaultAppLocalizations();
    final assets = DefaultAppAssets();
    final appCoordinator = AppCoordinator(
      connectFeatureProvider: connectFeatureProvider,
      sessionFeatureProvider: sessionFeatureProvider,
      songBookFeatureProvider: songBookFeatureProvider,
      downloadFeatureProvider: downloadFeatureProvider,
    );
    return MultiProvider(
      providers: [
        Provider<AppCoordinator>.value(value: appCoordinator),
        Provider<ConnectFlowController>.value(value: appCoordinator),
        Provider<ConnectLocalizations>.value(value: localizations),
        Provider<ConnectAssets>.value(value: assets),
        Provider<SessionNavigationCoordinator>.value(value: appCoordinator),
        Provider<SessionLocalizations>.value(value: localizations),
        Provider<SongBookNavigationCoordinator>.value(value: appCoordinator),
        Provider<SongBookLocalizations>.value(value: localizations),
        Provider<SongBookAssets>.value(value: assets),
        Provider<DownloadFlowController>.value(value: appCoordinator),
        Provider<DownloadLocalizations>.value(
            value: TemplateDownloadLocalizations()),
        connectFeatureProvider.providers,
        sessionFeatureProvider.providers,
        songBookFeatureProvider.providers,
      ],
      child: MaterialApp(
        title: 'Singalong UI Builder',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.tealAccent),
          useMaterial3: true,
        ),
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangeNotifierProvider<PreviewerViewModel>(
          create: (ctx) => DefaultPreviewerViewModel(
            connectFeatureProvider: connectFeatureProvider,
            sessionFeatureProvider: sessionFeatureProvider,
            songBookFeatureProvider: songBookFeatureProvider,
            downloadFeatureProvider: downloadFeatureProvider,
          ),
          child: const PreviewerView(),
        ),
      ),
    );
  }
}
