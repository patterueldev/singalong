import 'package:flutter/material.dart';
import 'package:playerfeature/playerfeature.dart';
import 'package:playerfeatureds/playerfeatureds.dart';
import 'package:provider/provider.dart';
import 'package:singalong_api_client/singalong_api_client.dart';
import 'package:video_player/video_player.dart';

import 'gen/assets.gen.dart';

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
      darkTheme: ThemeData.dark(),
      home: const PlayerWrapper(),
    );
  }
}

class PlayerWrapper extends StatefulWidget {
  const PlayerWrapper({super.key});

  @override
  State<PlayerWrapper> createState() => _PlayerWrapperState();
}

class _PlayerWrapperState extends State<PlayerWrapper> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      processVideo();
    });
  }

  void processVideo() async {
    _controller?.pause();
    _controller?.dispose();

    final configuration = context.read<SingalongAPIConfiguration>();
    final host = configuration.host;
    // TODO: this will be customizable in the future
    final url = "http://$host:9000/assets/flames-loop.mp4";
    final uri = Uri.parse(url);
    debugPrint("Loading video from $uri");
    final controller = VideoPlayerController.networkUrl(uri);
    _controller = controller;
    await _controller?.initialize();
    _controller?.setLooping(true);
    setState(() {});
    _controller?.play();
  }

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black,
        child: Stack(
          children: [
            _buildBackground(_controller),
            context.read<PlayerFeatureBuilder>().buildPlayerView()
          ],
        ),
      );

  Widget _buildBackground(VideoPlayerController? controller) {
    if (controller == null) {
      // placeholder
      return Assets.images.videoplayerBg
          .image(fit: BoxFit.contain, color: Colors.greenAccent);
    }
    return VideoPlayer(controller);
  }

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }
}
