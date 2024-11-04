import 'package:connectfeature/connectfeature.dart';
import 'package:downloadfeature/downloadfeature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:songbookfeature/songbookfeature.dart';

import '../splash/splash_coordinator.dart';

class MobileAppCoordinator
    implements
        SplashFlowCoordinator,
        ConnectFlowCoordinator,
        SessionFlowCoordinator,
        SongBookFlowCoordinator,
        DownloadFlowController {
  @override
  void onUnauthenticated(BuildContext context) {
    final connectProvider = context.read<ConnectFeatureBuilder>();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => connectProvider.buildConnectView(context),
      ),
    );
  }

  @override
  void onAuthenticated(
    BuildContext context, {
    String? redirectPath,
  }) {
    // TODO: implement onAuthenticated
  }

  @override
  void onConnected(BuildContext context) {
    SessionFeatureBuilder sessionFeatureBuilder = context.read();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (context) => sessionFeatureBuilder.buildSessionView()),
    );
  }

  @override
  void onDisconnected(BuildContext context) {
    // TODO: implement onDisconnected
  }

  @override
  void onSongBook(BuildContext context) {
    SongBookFeatureProvider songBookFeatureProvider = context.read();
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) =>
              songBookFeatureProvider.buildSongBookView(context: context)),
    );
  }

  @override
  void openDownloadScreen(BuildContext context) {
    DownloadFeatureProvider downloadFeatureProvider = context.read();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            downloadFeatureProvider.buildIdentifyUrlView(context: context),
      ),
    );
  }

  @override
  void openSongDetailScreen(BuildContext context, SongItem song) {
    // TODO: implement openSongDetailScreen
  }

  @override
  void navigateToIdentifiedSongDetailsView(BuildContext context,
      {required IdentifiedSongDetails details}) {
    DownloadFeatureProvider downloadFeatureProvider = context.read();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => downloadFeatureProvider.buildSongDetailsView(
          context: context,
          identifiedSongDetails: details,
        ),
      ),
    );
  }

  @override
  void onDownloadSuccess(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }
}
