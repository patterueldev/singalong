import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../splash/splash_screen.dart';
import '../splash/splash_viewmodel.dart';
import 'routes.dart';

class ControllerWebApp extends StatelessWidget {
  const ControllerWebApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Singalong',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(),
      onGenerateRoute: (settings) => onGenerateRoute(settings, context),
      themeMode: ThemeMode.dark,
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChangeNotifierProvider<SplashScreenViewModel>(
        create: (_) => DefaultSplashScreenViewModel(),
        child: SplashScreen(flow: context.read()),
      ),
    );
  }
}
