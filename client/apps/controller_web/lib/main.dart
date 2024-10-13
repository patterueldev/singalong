import 'package:connectfeature/connectfeature.dart';
import 'package:controller_web/routes.dart';
import 'package:controller_web/splash/splash_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;

import 'assets/app_assets.dart';
import 'controller_app.dart';
import 'coordinator/app_coordinator.dart';
import 'localizations/app_localizations.dart';

String getBaseUrl() {
  final location = html.window.location;
  return '${location.protocol}//${location.host}:8080';
}

void main() {
  final localizations = DefaultAppLocalizations();
  final connectFeatureProvider = ConnectFeatureProvider();
  final assets = DefaultAppAssets();
  final appCoordinator = AppCoordinator(
    connectFeatureProvider: connectFeatureProvider,
  );

  runApp(MultiProvider(
    providers: [
      Provider.value(value: connectFeatureProvider),
      Provider<ConnectAssets>.value(value: assets),
      Provider<ConnectFlowController>.value(value: appCoordinator),
      Provider<ConnectLocalizations>.value(value: localizations),
      connectFeatureProvider.providers,
    ],
    child: const ControllerApp(),
  ));
}
