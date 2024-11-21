part of '../playerfeature.dart';

class PlayerView extends StatelessWidget {
  const PlayerView({super.key});

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
                        child: ValueListenableBuilder(
                            valueListenable: viewModel.roomIdNotifier,
                            builder: (_, roomId, __) {
                              return roomId != null
                                  ? ConnectivityPanelWidget(
                                      host: viewModel.configuration.host,
                                      roomId: roomId,
                                    )
                                  : SizedBox.shrink();
                            }),
                      ),
                      Expanded(
                        flex: 9,
                        child: Column(
                          children: [
                            Expanded(
                              child: _buildBody(context, viewModel),
                            ),
                          ],
                        ),
                      ),
                      // right panel
                      Expanded(
                        flex: 1,
                        child: ValueListenableBuilder(
                          valueListenable: viewModel.isConnected,
                          builder: (context, isConnected, __) => isConnected
                              ? context
                                  .read<PlayerFeatureUIBuilder>()
                                  .buildParticipantsPanelWidget(context)
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildBody(BuildContext context, PlayerViewModel viewModel) => Column(
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
                  return _buildIdleConnected(context);
                }
                if (state is PlayerViewPlaying) {
                  return _buildPlaying(state);
                }
                if (state is PlayerViewScore) {
                  return _buildScore(state);
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
          onPressed: () => viewModel.setup(),
          child: Text('Start Session!'),
        ),
      );

  Widget _buildLoading() => const Center(
        child: CircularProgressIndicator(),
      );

  // could be a video player with "idle" video
  Widget _buildIdleConnected(BuildContext context) => Container(
        child: Center(
          child: Text(
            'Select a song to play',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );

  Widget _buildPlaying(PlayerViewPlaying state) => Column(
        children: [
          Expanded(
            child: Center(
              child: state.videoPlayerController.value.isInitialized
                  ? VideoPlayer(state.videoPlayerController)
                  : CircularProgressIndicator(),
            ),
          ),
          // progress bar/seek bar
          ValueListenableBuilder(
              valueListenable: state.currentSeekValueNotifier,
              builder: (_, value, __) {
                return Slider(
                  value: value,
                  min: 0,
                  max: state.maxSeekValue,
                  onChanged: (value) {
                    state.currentSeekValueNotifier.value = value;
                  },
                  onChangeEnd: (value) {
                    state.videoPlayerController
                        .seekTo(Duration(seconds: value.toInt()));
                  },
                );
              }),
        ],
      );

  Widget _buildScore(PlayerViewScore state) => Center(
        child: Stack(
          children: [
            state.videoPlayerController != null
                ? VideoPlayer(state.videoPlayerController!)
                : SizedBox.shrink(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.score.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildErrorWithRetry(String error, PlayerViewModel viewModel) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $error', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.setup(),
              child: Text('Retry'),
            ),
          ],
        ),
      );
}
