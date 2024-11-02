import 'package:connectfeature/connectfeature.dart';
import 'package:controller_web/splash/splash_coordinator.dart';
import 'package:controller_web/web/routes.dart';
import 'package:flutter/material.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:songbookfeature/songbookfeature.dart';

class WebAppCoordinator
    implements
        SplashFlowCoordinator,
        ConnectFlowCoordinator,
        SessionFlowCoordinator,
        SongBookFlowCoordinator {
  const WebAppCoordinator();

  @override
  void onUnauthenticated(BuildContext context) {
    AppRoute.connect.pushReplacement(context);
  }

  @override
  void onAuthenticated(BuildContext context) {
    // TODO: Polish this
    // if current address is '/' or '/connect', pushReplacementNamed('/session')
    if (ModalRoute.of(context)!.settings.name == '/' ||
        ModalRoute.of(context)!.settings.name == '/connect') {
      Navigator.of(context).pushReplacementNamed('/session');
    } else {
      // retain the current address
      // get the current address
      final uri = Uri.parse(ModalRoute.of(context)!.settings.name ?? '');
      // push the current address
      Navigator.of(context).pushReplacementNamed(uri.path);
      // dunno if this will work, yet
    }
  }

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
    // TODO: implement openDownloadScreen
  }
}
