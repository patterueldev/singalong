import 'package:connectfeature/connectfeature.dart';
import 'package:controller/splash/splash_coordinator.dart';
import 'package:controller/web/on_generate_routes.dart';
import 'package:controller/web/webapp_coordinator.dart';
import 'package:downloadfeature/downloadfeature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:core/core.dart';
import 'package:singalong_api_client/singalong_api_client.dart';
import 'package:songbookfeature/songbookfeature.dart';
import 'package:url_strategy/url_strategy.dart';
import 'dart:html' as html;
import '_main.dart';

import 'web/controller_webapp.dart';

class APIConfiguration extends SingalongConfiguration {
  @override
  final String protocol = 'http';

  @override
  late final String host = _host;

  String get _host {
    final location = html.window.location;
    // host contains a port number; we need to remove it
    final host = location.host.split(':')[0];
    return host;
  }

  @override
  final int apiPort = 8080;

  @override
  final int socketPort = 9092;

  @override
  final int storagePort = 9000;

  @override
  final String persistenceStorageKey = "1234567890123456";
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const appCoordinator = WebAppCoordinator();

  setPathUrlStrategy();

  runApp(MultiProvider(
    providers: [
      Provider<SplashFlowCoordinator>.value(value: appCoordinator),
      Provider<ConnectFlowCoordinator>.value(value: appCoordinator),
      Provider<SessionFlowCoordinator>.value(value: appCoordinator),
      Provider<SongBookFlowCoordinator>.value(value: appCoordinator),
      Provider<DownloadFlowCoordinator>.value(value: appCoordinator),
      Provider<SingalongConfiguration>.value(value: APIConfiguration()),
      buildProviders(),
    ],
    child: const ControllerWebApp(),
    // child: ChangeNotifierProvider<AppViewModel>(
    //   create: (context) => AppViewModelImpl(),
    //   child: const ControllerWebApp(),
    // ),
  ));
}
