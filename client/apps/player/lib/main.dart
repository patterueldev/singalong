import 'package:commonds/commonds.dart';
import 'package:flutter/material.dart';
import 'package:playerfeature/playerfeature.dart';
import 'package:playerfeatureds/playerfeatureds.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:singalong_api_client/singalong_api_client.dart';
import 'package:video_player/video_player.dart';

import '_main.dart';
import 'gen/assets.gen.dart';

void main() {
  final singalongAPIClientProvider = SingalongAPIClientProvider();
  final commonProvider = CommonProvider();
  final playerFeatureDSProvider = PlayerFeatureDSProvider();
  runApp(MultiProvider(
    providers: [
      Provider<SingalongConfiguration>.value(value: APIConfiguration()),
      singalongAPIClientProvider.providers,
      commonProvider.providers,
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
      themeMode: ThemeMode.dark,
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

    final configuration = context.read<SingalongConfiguration>();
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
            context.read<PlayerFeatureUIBuilder>().buildPlayerView()
          ],
        ),
      );

  Widget _buildBackground(VideoPlayerController? controller) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: controller != null
                ? VideoPlayer(controller)
                : Assets.images.videoplayerBg.image(fit: BoxFit.cover),
          )
        ],
      );

  @override
  void dispose() {
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }
}
