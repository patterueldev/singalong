part of '../playerfeature.dart';

class PlayerView extends StatefulWidget {
  const PlayerView({super.key, required this.viewModel});

  final PlayerViewModel viewModel;

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  PlayerViewModel get viewModel => widget.viewModel;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
            body: _buildBody(),
          ),
        ],
      );

  Widget _buildBody() => Column(
        children: [
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: viewModel.playerViewStateNotifier,
              builder: (_, state, child) {
                if (state is PlayerViewPlaying) {
                  return _buildPlaying(state.videoPlayerController);
                }
                return _buildIdle();
              },
            ),
          ),
        ],
      );

  Widget _buildIdle() => Center(
        child: ElevatedButton(
          onPressed: () => viewModel.setupSession(),
          child: Text('Load'),
        ),
      );

  Widget _buildPlaying(VideoPlayerController controller) => Center(
        child: controller.value.isInitialized
            ? VideoPlayer(controller)
            : CircularProgressIndicator(),
      );
}
