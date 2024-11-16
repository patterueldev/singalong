import 'package:connectfeature/connectfeature.dart';
import 'package:controller/splash/splash_coordinator.dart';
import 'package:controller/splash/splash_screen.dart';
import 'package:controller/splash/splash_viewmodel.dart';
import 'package:downloadfeature/downloadfeature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:core/core.dart';
import 'package:singalong_api_client/singalong_api_client.dart';
import 'package:songbookfeature/songbookfeature.dart';
import '_main.dart';

import 'api_configuration.dart';
import 'mobile/controller_mobileapp.dart';
import 'mobile/mobile_appcoordinator.dart';

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
