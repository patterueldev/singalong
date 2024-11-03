import 'package:connectfeature/connectfeature.dart';
import 'package:controller/splash/splash_coordinator.dart';
import 'package:controller/web/webapp_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:singalong_api_client/singalong_api_client.dart';
import 'package:songbookfeature/songbookfeature.dart';
import 'dart:html' as html;
import '_main.dart';

import 'web/controller_webapp.dart';

class APIConfiguration extends SingalongAPIConfiguration {
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
}

void main() {
  final appCoordinator = WebAppCoordinator();

  runApp(MultiProvider(
    providers: [
      Provider<SplashFlowCoordinator>.value(value: appCoordinator),
      Provider<ConnectFlowCoordinator>.value(value: appCoordinator),
      Provider<SessionFlowCoordinator>.value(value: appCoordinator),
      Provider<SongBookFlowCoordinator>.value(value: appCoordinator),
      Provider<SingalongAPIConfiguration>.value(value: APIConfiguration()),
      buildProviders(),
    ],
    child: const ControllerWebApp(),
  ));
}
