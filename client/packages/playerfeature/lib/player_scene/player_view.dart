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
      context.read<PlayerViewModel>().authorizeConnection();
    });
  }

  @override
  Widget build(BuildContext context) => Consumer<PlayerViewModel>(
        builder: (_, viewModel, __) => Scaffold(
          backgroundColor: Colors.black,
          body: Row(
            children: [
              // contains the video player and reserved widget
              Expanded(
                flex: 9,
                child: Column(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        alignment: Alignment.topLeft,
                        color: Colors.black.withOpacity(0.5),
                        padding: const EdgeInsets.only(top: 16, bottom: 16),
                        child: const ReservedWidget(),
                      ),
                    ),
                    Expanded(flex: 9, child: _buildBody(viewModel)),
                  ],
                ),
              ),
              // This will contain some panel for the participants
              Expanded(
                flex: 3,
                child: Container(),
              ),
            ],
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
                if (state is PlayerViewPlaying) {
                  return _buildPlaying(state.videoPlayerController);
                }
                if (state is PlayerViewScore) {
                  return _buildScore(state.score);
                }
                if (state is PlayerViewFailure) {
                  return _buildErrorWithRetry(state.errorMessage, viewModel);
                }
                return _buildIdle(viewModel);
              },
            ),
          ),
        ],
      );

  Widget _buildIdle(PlayerViewModel viewModel) => Center(
        child: ElevatedButton(
          onPressed: () => viewModel.setupListeners(),
          child: Text('Start Session!'),
        ),
      );

  Widget _buildLoading() => Center(
        child: CircularProgressIndicator(),
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
              onPressed: () => viewModel.authorizeConnection(),
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
