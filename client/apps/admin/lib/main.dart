import 'package:adminfeature/adminfeature.dart';
import 'package:adminfeatureds/adminfeatureds.dart';
import 'package:commonds/commonds.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import 'package:singalong_api_client/singalong_api_client.dart';

import '_main.dart';

// TODO: TEMPORARY Configuration
class APIConfiguration extends SingalongConfiguration {
  @override
  final String protocol = 'http';

  @override
  late final String host = _host;

  String get _host {
    final host = "thursday.local";
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
  final singalongAPIClientProvider = SingalongAPIClientProvider();
  final commonProvider = CommonProvider();
  final adminFeatureDSProvider = AdminFeatureDSProvider();
  runApp(MultiProvider(
    providers: [
      Provider<SingalongConfiguration>.value(value: APIConfiguration()),
      singalongAPIClientProvider.providers,
      commonProvider.providers,
      adminFeatureDSProvider.providers,
    ],
    child: const AdminApp(),
  ));
}
