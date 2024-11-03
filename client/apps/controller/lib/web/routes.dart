import 'package:connectfeature/connectfeature.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;

import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:songbookfeature/songbookfeature.dart';

import '../splash/splash_screen.dart';
import '../splash/splash_viewmodel.dart';

Route<dynamic>? onGenerateRoute(RouteSettings settings, BuildContext context) {
  final uri = Uri.parse(settings.name ?? '');
  debugPrint('onGenerateRoute: ${uri.path}');
  debugPrint('onGenerateRoute queryParameters: ${uri.queryParameters}');
  html.window.history.pushState(null, '', uri.path);

  final route = AppRoute.fromPath(uri.path);
  switch (route) {
    case AppRoute.initial:
      return MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider<SplashScreenViewModel>(
          create: (_) => DefaultSplashScreenViewModel(),
          child: SplashScreen(flow: context.read()),
        ),
      );
    case AppRoute.connect:
      final connectProvider = context.read<ConnectFeatureBuilder>();
      return MaterialPageRoute(
        builder: (context) => connectProvider.buildConnectView(
          name: 'natsumi',
          roomId: '569841',
        ),
      );
    case AppRoute.session:
      return MaterialPageRoute(
        builder: (context) =>
            context.read<SessionFeatureBuilder>().buildSessionView(),
      );
    case AppRoute.songBook:
      return MaterialPageRoute(
        builder: (context) => context
            .read<SongBookFeatureProvider>()
            .buildSongBookView(context: context),
      );
    case AppRoute.notFound:
      return MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Center(
            child: Text('404 Not Found'),
          ),
        ),
      );
  }
}

enum AppRoute {
  initial,
  connect,
  session,
  songBook,
  notFound,
  ;

  String get path {
    switch (this) {
      case AppRoute.initial:
        return '/';
      case AppRoute.connect:
        return '/connect';
      case AppRoute.session:
        return '/session';
      case AppRoute.songBook:
        return '/songbook';
      case AppRoute.notFound:
        return '/404';
    }
  }

  void pushReplacement(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(path);
  }

  void push(BuildContext context) {
    Navigator.of(context).pushNamed(path);
  }

  static AppRoute fromPath(String path) => AppRoute.values.firstWhere(
        (element) => element.path == path,
        orElse: () => AppRoute.notFound,
      );
}
