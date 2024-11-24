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

import 'mobile/controller_mobileapp.dart';
import 'mobile/mobile_appcoordinator.dart';

class APIConfiguration extends SingalongConfiguration {
  @override
  final String defaultApiHost;

  APIConfiguration({
    this.defaultApiHost = 'thursday.local',
  });

  @override
  final String persistenceStorageKey = "1234567890123456";
}
