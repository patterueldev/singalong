import 'package:connectfeature/connectfeature.dart';
import 'package:controller_web/mobile/controller_mobileapp.dart';
import 'package:controller_web/splash/splash_screen.dart';
import 'package:controller_web/splash/splash_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:singalong_api_client/singalong_api_client.dart';
import 'package:songbookfeature/songbookfeature.dart';
import '_main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'mobile/mobile_appcoordinator.dart';

class APIConfiguration extends SingalongAPIConfiguration {
  @override
  final String protocol = 'http';

  @override
  String host = 'thursday.local';

  @override
  final int apiPort = 8080;

  @override
  final int socketPort = 9092;
}

void main() {
  final appCoordinator = MobileAppCoordinator();

  runApp(MultiProvider(
    providers: [
      Provider<ConnectFlowCoordinator>.value(value: appCoordinator),
      Provider<SessionFlowCoordinator>.value(value: appCoordinator),
      Provider<SongBookFlowCoordinator>.value(value: appCoordinator),
      Provider<SingalongAPIConfiguration>.value(value: APIConfiguration()),
      buildProviders(),
    ],
    child: const ControllerMobileApp(),
  ));
}

class ControllerApp extends StatelessWidget {
  const ControllerApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Singalong',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChangeNotifierProvider<SplashScreenViewModel>(
        create: (_) => DefaultSplashScreenViewModel(),
        child: const SplashScreen(),
      ),
    );
  }
}
