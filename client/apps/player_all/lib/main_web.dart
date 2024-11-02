import 'package:flutter/material.dart';
import 'package:playerfeature/playerfeature.dart';
import 'package:playerfeatureds/playerfeatureds.dart';
import 'package:provider/provider.dart';
import 'package:singalong_api_client/singalong_api_client.dart';

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

void main() async {
  final singalongAPIClientProvider = SingalongAPIClientProvider();
  final playerFeatureDSProvider = PlayerFeatureDSProvider();
  runApp(MultiProvider(
    providers: [
      Provider<SingalongAPIConfiguration>.value(value: APIConfiguration()),
      singalongAPIClientProvider.providers,
      playerFeatureDSProvider.providers,
    ],
    child: const PlayerApp(),
  ));
}

class PlayerApp extends StatelessWidget {
  const PlayerApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Singalong Player',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: context.read<PlayerFeatureBuilder>().buildPlayerView(),
    );
  }
}
