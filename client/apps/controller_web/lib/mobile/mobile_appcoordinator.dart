import 'package:connectfeature/connectfeature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:sessionfeatureds/sessionfeatureds.dart';
import 'package:songbookfeature/songbookfeature.dart';

class MobileAppCoordinator
    implements
        ConnectFlowCoordinator,
        SessionFlowCoordinator,
        SongBookFlowCoordinator {
  const MobileAppCoordinator();

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
}
