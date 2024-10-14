import 'package:connectfeature/connectfeature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';

class AppCoordinator implements ConnectFlowCoordinator, SessionFlowCoordinator {
  const AppCoordinator();

  @override
  void onConnected(BuildContext context) {
    final sessionBuilder = context.read<SessionFeatureBuilder>();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        settings: const RouteSettings(name: "Song Book"),
        builder: (context) => sessionBuilder.buildSessionView(),
      ),
    );
  }

  @override
  void onDisconnected(BuildContext context) {
    // TODO: implement onDisconnected
  }

  @override
  void onSongBook(BuildContext context) {
    // TODO: implement onSongBook
  }
}
