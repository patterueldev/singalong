import 'package:connectfeature/connectfeature.dart';
import 'package:downloadfeature/downloadfeature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:songbookfeature/songbookfeature.dart';

import '../splash/splash_screen.dart';
import '../splash/splash_viewmodel.dart';
import 'approute.dart';

class ScreenRouteBuilder {
  PageRoute buildConnectRoute(BuildContext context,
      {String? name, String? roomId}) {
    final connectProvider = context.read<ConnectFeatureBuilder>();
    return MaterialPageRoute(
      builder: (context) => connectProvider.buildConnectView(
        context,
        name: name ?? '',
        roomId: roomId ?? '',
      ),
      settings: RouteSettings(name: AppRoute.sessionConnect.path),
    );
  }

  PageRoute buildSessionRoute(BuildContext context) => MaterialPageRoute(
        builder: (context) =>
            context.read<SessionFeatureBuilder>().buildSessionView(),
        settings: RouteSettings(name: AppRoute.session.path),
      );

  PageRoute buildSongBookRoute(BuildContext context) => MaterialPageRoute(
        builder: (context) => context
            .read<SongBookFeatureProvider>()
            .buildSongBookView(context: context),
        settings: RouteSettings(name: AppRoute.songBook.path),
      );

  PageRoute buildDownloadRoute(BuildContext context) => MaterialPageRoute(
        builder: (context) => context
            .read<DownloadFeatureProvider>()
            .buildIdentifyUrlView(context: context),
        settings: RouteSettings(name: AppRoute.download.path),
      );

  PageRoute buildIdentifiedSongDetailsRoute(
          BuildContext context, IdentifiedSongDetails identifiedSongDetails) =>
      MaterialPageRoute(
        builder: (context) =>
            context.read<DownloadFeatureProvider>().buildSongDetailsView(
                  context: context,
                  identifiedSongDetails: identifiedSongDetails,
                ),
        settings: RouteSettings(name: AppRoute.identifiedSongDetails.path),
      );

  PageRoute buildNotFoundRoute(BuildContext context) => MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Center(
            child: Text('404 Not Found'),
          ),
        ),
        settings: RouteSettings(name: AppRoute.notFound.path),
      );
}
