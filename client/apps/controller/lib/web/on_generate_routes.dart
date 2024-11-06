import 'package:connectfeature/connectfeature.dart';
import 'package:downloadfeature/downloadfeature.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;

import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:songbookfeature/songbookfeature.dart';

import '../splash/splash_provider.dart';
import '../splash/splash_screen.dart';
import '../splash/splash_viewmodel.dart';
import '../splash/web_splash_viewmodel.dart';
import 'approute.dart';

Route<dynamic>? onGenerateRoute(RouteSettings settings, BuildContext context) {
  debugPrint("settings: $settings");
  debugPrint("name: ${settings.name}");
  final uri = Uri.parse(settings.name ?? '');
  debugPrint('onGenerateRoute path: ${uri.path}');
  debugPrint('onGenerateRoute queryParameters: ${uri.queryParameters}');
  final route = AppRoute.fromPath(uri.path);
  switch (route) {
    case AppRoute.initial:
      return MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider<SplashScreenViewModel>(
          create: (context) =>
              WebSplashScreenViewModel(persistenceService: context.read()),
          child: SplashScreen(flow: context.read()),
        ),
      );
    case AppRoute.sessionConnect:
      final roomId = uri.queryParameters['roomId'];
      return MaterialPageRoute(
        builder: (context) => context
            .read<ConnectFeatureBuilder>()
            .buildConnectView(context, roomId: roomId),
      );
    case AppRoute.session:
      return MaterialPageRoute(
        builder: (context) =>
            context.read<SessionFeatureBuilder>().buildSessionView(context),
      );
    case AppRoute.songBook:
      return MaterialPageRoute(
        builder: (context) => context
            .read<SongBookFeatureProvider>()
            .buildSongBookView(context: context),
      );
    case AppRoute.downloadables:
      final query = settings.arguments as String?;
      return MaterialPageRoute(
        builder: (context) => context
            .read<DownloadFeatureProvider>()
            .buildSearchDownloadableView(query: query),
      );
    case AppRoute.identify:
      final String? url = settings.arguments as String?;
      return MaterialPageRoute(
        builder: (context) => context
            .read<DownloadFeatureProvider>()
            .buildIdentifyUrlView(context: context, url: url),
      );
    case AppRoute.identifiedSongDetails:
      final details = settings.arguments as IdentifiedSongDetails;
      return MaterialPageRoute(
        builder: (context) => context
            .read<DownloadFeatureProvider>()
            .buildSongDetailsView(
                context: context, identifiedSongDetails: details),
      );
    default:
      return MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Center(child: Text('Page not found')),
        ),
      );
  }
}
