import 'package:adminfeature/adminfeature.dart';
import 'package:adminfeatureds/adminfeatureds.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:singalong_api_client/singalong_api_client.dart';

import '_main.dart';

// TODO: TEMPORARY Configuration
class APIConfiguration extends SingalongAPIConfiguration {
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
}

void main() {
  final singalongAPIClientProvider = SingalongAPIClientProvider();
  final adminFeatureDSProvider = AdminFeatureDSProvider();
  runApp(MultiProvider(
    providers: [
      Provider<SingalongAPIConfiguration>.value(value: APIConfiguration()),
      singalongAPIClientProvider.providers,
      adminFeatureDSProvider.providers,
    ],
    child: const AdminApp(),
  ));
}
