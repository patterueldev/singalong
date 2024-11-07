import 'package:connectfeature/connectfeature.dart';
import 'package:controller/splash/splash_coordinator.dart';
import 'package:controller/splash/splash_screen.dart';
import 'package:controller/splash/splash_viewmodel.dart';
import 'package:downloadfeature/downloadfeature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:shared/shared.dart';
import 'package:singalong_api_client/singalong_api_client.dart';
import 'package:songbookfeature/songbookfeature.dart';
import '_main.dart';

import 'mobile/controller_mobileapp.dart';
import 'mobile/mobile_appcoordinator.dart';

class APIConfiguration extends SingalongConfiguration {
  @override
  final String protocol = 'http';

  @override
  String host = 'thursday.local';

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
  final appCoordinator = MobileAppCoordinator();

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
    child: const ControllerMobileApp(),
  ));
}
