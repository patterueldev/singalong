import 'package:connectfeature/connectfeature.dart';
import 'package:connectfeatureds/connectfeatureds.dart';
import 'package:controller_web/routes.dart';
import 'package:controller_web/splash/splash_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:sessionfeatureds/sessionfeatureds.dart';
import 'package:singalong_api_client/singalong_api_client.dart';
import 'dart:html' as html;

import 'assets/app_assets.dart';
import 'controller_app.dart';
import 'coordinator/app_coordinator.dart';
import 'localizations/app_localizations.dart';

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
  final singalongAPIClientProvider = SingalongAPIClientProvider();
  final connectFeatureDSProvider = ConnectFeatureDSProvider();
  final sessionFeatureDSProvider = SessionFeatureDSProvider();
  final localizations = DefaultAppLocalizations();
  final assets = DefaultAppAssets();
  final appCoordinator = AppCoordinator();

  runApp(MultiProvider(
    providers: [
      Provider<ConnectAssets>.value(value: assets),
      Provider<ConnectFlowCoordinator>.value(value: appCoordinator),
      Provider<ConnectLocalizations>.value(value: localizations),
      Provider<SessionFlowCoordinator>.value(value: appCoordinator),
      Provider<SessionLocalizations>.value(value: localizations),
      Provider<SingalongAPIConfiguration>.value(value: APIConfiguration()),
      singalongAPIClientProvider.providers,
      connectFeatureDSProvider.providers,
      sessionFeatureDSProvider.providers,
    ],
    child: const ControllerApp(),
  ));
}
