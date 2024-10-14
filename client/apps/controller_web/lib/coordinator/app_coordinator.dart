import 'package:connectfeature/connectfeature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';

class AppCoordinator implements ConnectFlowCoordinator, SessionFlowCoordinator {
  const AppCoordinator();

  @override
  void onConnected(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/session');
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
