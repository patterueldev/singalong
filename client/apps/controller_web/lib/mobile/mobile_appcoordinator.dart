import 'package:connectfeature/connectfeature.dart';
import 'package:controller_web/splash/splash_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:songbookfeature/songbookfeature.dart';

class MobileAppCoordinator
    implements
        SplashFlowCoordinator,
        ConnectFlowCoordinator,
        SessionFlowCoordinator,
        SongBookFlowCoordinator {
  @override
  void onUnauthenticated(BuildContext context) {
    final connectProvider = context.read<ConnectFeatureBuilder>();
    final route = MaterialPageRoute(
      builder: (context) => connectProvider.buildConnectView(
        name: 'natsumi',
        roomId: '569841',
      ),
    );
    Navigator.of(context).pushReplacement(route);
  }

  @override
  void onAuthenticated(BuildContext context) {
    // TODO: implement onAuthenticated
  }

  @override
  void onConnected(BuildContext context) {
    SessionFeatureBuilder sessionFeatureBuilder = context.read();
    Navigator.of(context).push(
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
    // TODO: implement openDownloadScreen
  }

  @override
  void openSongDetailScreen(BuildContext context, SongItem song) {
    // TODO: implement openSongDetailScreen
  }
}
