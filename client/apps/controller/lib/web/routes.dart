import 'package:connectfeature/connectfeature.dart';
import 'package:controller/splash/splash_provider.dart';
import 'package:controller/splash/splash_screen.dart';
import 'package:controller/web/approute.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:songbookfeature/songbookfeature.dart';

import '../splash/splash_viewmodel.dart';
import '../splash/web_splash_viewmodel.dart';

Map<String, Widget Function(BuildContext)> routes = {
  // AppRoute.initial.path: (context) =>
  //     context.read<SplashProvider>().buildSplashScreen(context),
  AppRoute.initial.path: (context) =>
      ChangeNotifierProvider<SplashScreenViewModel>(
        create: (context) => WebSplashScreenViewModel(
          connectRepository: context.read(),
          persistenceService: context.read(),
          configuration: context.read(),
        ),
        child: SplashScreen(flow: context.read()),
      ),
  AppRoute.sessionConnect.path: (context) =>
      context.read<ConnectFeatureBuilder>().buildConnectView(context),
  AppRoute.session.path: (context) =>
      context.read<SessionFeatureUIBuilder>().buildSessionView(context),
};
