part of '../playerfeature.dart';

class PlayerView extends StatefulWidget {
  const PlayerView({super.key});

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlayerViewModel>().establishConnection();
    });
  }

  @override
  Widget build(BuildContext context) => Consumer<PlayerViewModel>(
        builder: (_, viewModel, __) => Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                // vertical layout arrangement
                Expanded(
                  flex: 1,
                  child: Container(
                    alignment: Alignment.topLeft,
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    child: ValueListenableBuilder(
                      valueListenable: viewModel.isConnected,
                      builder: (_, isConnected, __) =>
                          isConnected ? ReservedWidget() : SizedBox.shrink(),
                    ),
                  ),
                ),

                // horizontal layout arrangement
                Expanded(
                  flex: 9,
                  child: Row(
                    children: [
                      // connectivity panel and video player
                      // left panel
                      Expanded(
                        flex: 1,
                        child: ConnectivityPanelWidget(),
                      ),
                      Expanded(
                        flex: 9,
                        child: Column(
                          children: [
                            Expanded(
                              child: _buildBody(viewModel),
                            ),
                          ],
                        ),
                      ),
                      // right panel
                      Expanded(
                        flex: 1,
                        child: Container(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildBody(PlayerViewModel viewModel) => Column(
        children: [
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: viewModel.playerViewStateNotifier,
              builder: (_, state, child) {
                debugPrint('PlayerViewState status: ${state.status}');
                if (state.status == PlayerViewStatus.loading) {
                  return _buildLoading();
                }
                if (state.status == PlayerViewStatus.idleConnected) {
                  return _buildIdleConnected();
                }
                if (state is PlayerViewPlaying) {
                  return _buildPlaying(state.videoPlayerController);
                }
                if (state is PlayerViewScore) {
                  return _buildScore(state.score);
                }
                if (state is PlayerViewFailure) {
                  return _buildErrorWithRetry(state.errorMessage, viewModel);
                }
                return _buildIdleDisconnected(viewModel);
              },
            ),
          ),
        ],
      );

  Widget _buildIdleDisconnected(PlayerViewModel viewModel) => Center(
        child: ElevatedButton(
          onPressed: () => viewModel.establishConnection(),
          child: Text('Start Session!'),
        ),
      );

  Widget _buildLoading() => Center(
        child: CircularProgressIndicator(),
      );

  // could be a video player with "idle" video
  Widget _buildIdleConnected() => Container(
        child: Center(
          child: Text(
            'Select a song to play',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );

  Widget _buildPlaying(VideoPlayerController controller) => Center(
        child: controller.value.isInitialized
            ? VideoPlayer(controller)
            : CircularProgressIndicator(),
      );

  Widget _buildScore(int score) => Center(
        child: Text('Score: $score'),
      );

  Widget _buildErrorWithRetry(String error, PlayerViewModel viewModel) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $error', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.establishConnection(),
              child: Text('Retry'),
            ),
          ],
        ),
      );

  @override
  void dispose() {
    super.dispose();
  }
}
