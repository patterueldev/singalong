import 'package:common/common.dart';
import 'package:connectfeature/connectfeature.dart';
import 'package:controller/web/approute.dart';
import 'package:controller/web/on_generate_routes.dart';
import 'package:downloadfeature/downloadfeature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:songbookfeature/songbookfeature.dart';
import 'package:url_launcher/url_launcher.dart';

import '../splash/splash_coordinator.dart';

class WebAppCoordinator
    implements
        SplashFlowCoordinator,
        ConnectFlowCoordinator,
        SessionFlowCoordinator,
        SongBookFlowCoordinator,
        DownloadFlowCoordinator {
  const WebAppCoordinator();

  @override
  void onUnauthenticated(BuildContext context) =>
      AppRoute.sessionConnect.pushReplacement(context);

  @override
  void onAuthenticated(BuildContext context, {String? redirectPath}) {
    if (redirectPath != null) {
      Navigator.of(context).pushReplacementNamed(redirectPath);
    } else {
      AppRoute.session.pushReplacement(context);
    }
  }

  @override
  void onConnected(BuildContext context) {
    AppRoute.session.pushReplacement(context);
  }

  @override
  void onDisconnected(BuildContext context) {
    AppRoute.initial.pushReplacement(context);
  }

  @override
  void onSongBook(BuildContext context, {String? roomId}) {
    AppRoute.songBook.push(context, arguments: roomId);
  }

  @override
  void onReserved(BuildContext context) {
    Navigator.of(context).popUntil((route) {
      return route.settings.name == '/session/active';
    });
  }

  @override
  void openSearchDownloadablesScreen(BuildContext context, {String? query}) {
    AppRoute.downloadables.push(context, arguments: query);
  }

  @override
  void openDownloadScreen(BuildContext context, {String? url}) {
    AppRoute.identify.push(context, arguments: url);
  }

  @override
  Future<T?> openSongDetailScreen<T>(BuildContext context, String songId) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.90,
          child: context.read<SongBookFeatureProvider>().buildSongDetailsView(
                context: context,
                songId: songId,
              ),
        ),
      );

  @override
  void navigateToIdentifiedSongDetailsView(BuildContext context,
      {required IdentifiedSongDetails details}) {
    AppRoute.identifiedSongDetails.push(context, arguments: details);
  }

  @override
  void onDownloadSuccess(BuildContext context) {
    Navigator.popUntil(context, (route) {
      return route.settings.name == '/session/active';
    });
  }

  @override
  void navigateToURLIdentifierView(BuildContext context) {
    openDownloadScreen(context);
  }

  @override
  void openURL(BuildContext context, Uri url) {
    debugPrint("Launching URL: $url");
    canLaunchUrl(url).then((canLaunch) async {
      if (!canLaunch) {
        debugPrint("Cannot launch URL: $url");
        return;
      }
      await launchUrl(url, mode: LaunchMode.externalApplication);
    });
  }
}
