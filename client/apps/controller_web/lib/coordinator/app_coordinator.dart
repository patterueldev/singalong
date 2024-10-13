import 'package:connectfeature/connectfeature.dart';
import 'package:flutter/material.dart';

class AppCoordinator implements ConnectFlowController {
  const AppCoordinator();

  @override
  void onConnected(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          settings: const RouteSettings(name: "Song Book"),
          builder: (context) => Container()),
    );
  }
}
