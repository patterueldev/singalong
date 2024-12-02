import 'package:controller/splash/splash_provider.dart';
import 'package:controller/web/approute.dart';
import 'package:controller/web/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../splash/splash_screen.dart';
import '../splash/splash_viewmodel.dart';
import 'on_generate_routes.dart';

class ControllerWebApp extends StatelessWidget {
  const ControllerWebApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Singalong',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
          useMaterial3: true,
        ),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        routes: routes,
        onGenerateRoute: (settings) => onGenerateRoute(settings, context),
      );
}
