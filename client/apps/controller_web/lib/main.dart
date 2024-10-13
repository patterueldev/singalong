import 'package:connectfeature/connectfeature.dart';
import 'package:connectfeatureds/connectfeatureds.dart';
import 'package:controller_web/routes.dart';
import 'package:controller_web/splash/splash_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:singalong_api_client/singalong_api_client.dart';
import 'dart:html' as html;

import 'assets/app_assets.dart';
import 'controller_app.dart';
import 'coordinator/app_coordinator.dart';
import 'localizations/app_localizations.dart';

String getBaseUrl() {
  final location = html.window.location;
  // host contains a port number; we need to remove it
  final host = location.host.split(':')[0];
  return '${location.protocol}//$host:8080';
}

class APIConfiguration implements SingalongAPIConfiguration {
  @override
  String baseUrl = getBaseUrl();
}

void main() {
  final singalongAPIClientProvider = SingalongAPIClientProvider();
  final connectFeatureDSProvider = ConnectFeatureDSProvider();
  final localizations = DefaultAppLocalizations();
  final assets = DefaultAppAssets();
  final appCoordinator = AppCoordinator();

  runApp(MultiProvider(
    providers: [
      Provider<ConnectAssets>.value(value: assets),
      Provider<ConnectFlowController>.value(value: appCoordinator),
      Provider<ConnectLocalizations>.value(value: localizations),
      Provider<SingalongAPIConfiguration>.value(value: APIConfiguration()),
      singalongAPIClientProvider.providers,
      connectFeatureDSProvider.providers,
    ],
    child: const ControllerApp(),
  ));
}
