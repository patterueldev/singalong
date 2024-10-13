import 'package:connectfeature/connectfeature.dart';
import 'package:controller_web/routes.dart';
import 'package:controller_web/splash/splash_screen.dart';
import 'package:controller_web/splash/splash_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'assets/app_assets.dart';
import 'coordinator/app_coordinator.dart';
import 'localizations/app_localizations.dart';

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
      // localizationsDelegates: const [AppLocalizations.delegate],
      // supportedLocales: AppLocalizations.supportedLocales,
      onGenerateRoute: (settings) => onGenerateRoute(settings, context),
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChangeNotifierProvider<SplashScreenViewModel>(
        create: (_) => DefaultSplashScreenViewModel(),
        child: const SplashScreen(),
      ),
    );
  }
}
