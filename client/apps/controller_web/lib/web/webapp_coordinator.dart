import 'package:connectfeature/connectfeature.dart';
import 'package:controller_web/web/routes.dart';
import 'package:flutter/material.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:songbookfeature/songbookfeature.dart';

class WebAppCoordinator
    implements
        ConnectFlowCoordinator,
        SessionFlowCoordinator,
        SongBookFlowCoordinator {
  const WebAppCoordinator();

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
