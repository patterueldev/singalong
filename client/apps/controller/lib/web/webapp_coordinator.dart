import 'package:connectfeature/connectfeature.dart';
import 'package:controller/web/approute.dart';
import 'package:controller/web/on_generate_routes.dart';
import 'package:downloadfeature/downloadfeature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:songbookfeature/songbookfeature.dart';

import '../splash/splash_coordinator.dart';

class WebAppCoordinator
    implements
        SplashFlowCoordinator,
        ConnectFlowCoordinator,
        SessionFlowCoordinator,
        SongBookFlowCoordinator,
        DownloadFlowController {
  const WebAppCoordinator();

  @override
  void onUnauthenticated(BuildContext context) =>
      AppRoute.sessionConnect.pushReplacement(context);

  @override
  void onAuthenticated(BuildContext context, {String? redirectPath}) {}

  @override
  void onConnected(BuildContext context) {
    AppRoute.session.pushReplacement(context);
  }

  @override
  void onDisconnected(BuildContext context) {
    // TODO: implement onDisconnected
  }

  @override
  void onSongBook(BuildContext context) {
    AppRoute.songBook.push(context);
  }

  @override
  void openDownloadScreen(BuildContext context) {
    AppRoute.identify.push(context);
  }

  @override
  void openSongDetailScreen(BuildContext context, SongItem song) {
    // TODO: implement openSongDetailScreen
  }

  @override
  void navigateToIdentifiedSongDetailsView(BuildContext context,
      {required IdentifiedSongDetails details}) {
    AppRoute.identifiedSongDetails.push(context, arguments: details);
  }

  @override
  void onDownloadSuccess(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
