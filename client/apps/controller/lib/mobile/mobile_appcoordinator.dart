import 'package:connectfeature/connectfeature.dart';
import 'package:downloadfeature/downloadfeature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:songbookfeature/songbookfeature.dart';
import 'package:url_launcher/url_launcher.dart';

import '../splash/mobile_splash_viewmodel.dart';
import '../splash/splash_coordinator.dart';
import '../splash/splash_screen.dart';
import '../splash/splash_viewmodel.dart';

class MobileAppCoordinator
    implements
        SplashFlowCoordinator,
        ConnectFlowCoordinator,
        SessionFlowCoordinator,
        SongBookFlowCoordinator,
        DownloadFlowCoordinator {
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
    debugPrint(
        "Is Authenticated, will redirect to $redirectPath or session view");
    SessionFeatureUIBuilder sessionFeatureBuilder = context.read();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (context) =>
              sessionFeatureBuilder.buildSessionView(context)),
    );
  }

  @override
  void onConnected(BuildContext context) {
    SessionFeatureUIBuilder sessionFeatureBuilder = context.read();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (context) =>
              sessionFeatureBuilder.buildSessionView(context)),
    );
  }

  @override
  void onDisconnected(BuildContext context) {
    debugPrint("Disconnected, will redirect to splash screen");
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider<SplashScreenViewModel>(
          create: (_) => MobileSplashScreenViewModel(
            connectRepository: context.read(),
            persistenceService: context.read(),
            configuration: context.read(),
          ),
          child: SplashScreen(flow: context.read()),
        ),
      ),
    );
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
  void openSearchDownloadablesScreen(BuildContext context, {String? query}) {
    DownloadFeatureProvider downloadFeatureProvider = context.read();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            downloadFeatureProvider.buildSearchDownloadableView(query: query),
      ),
    );
  }

  @override
  void openDownloadScreen(BuildContext context, {String? url}) {
    DownloadFeatureProvider downloadFeatureProvider = context.read();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => downloadFeatureProvider.buildIdentifyUrlView(
            context: context, url: url),
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

  @override
  void navigateToURLIdentifierView(BuildContext context) {
    openDownloadScreen(context);
  }

  @override
  void previewDownloadable(
      BuildContext context, DownloadableItem downloadable) {
    final sourceUrl = downloadable.sourceUrl;
    final url = Uri.parse(sourceUrl);
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
