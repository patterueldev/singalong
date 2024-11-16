part of '../adminfeature.dart';

class PlayerControlPanelWidget extends StatelessWidget {
  const PlayerControlPanelWidget({super.key});

  @override
  Widget build(BuildContext context) => Consumer<PlayerControlPanelViewModel>(
        builder: (context, viewModel, child) => _build(context, viewModel),
      );

  Widget _build(BuildContext context, PlayerControlPanelViewModel viewModel) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder(
              valueListenable: viewModel.stateNotifier,
              builder: (context, value, child) {
                if (value is InactiveState) {
                  return _buildActive(context, value, viewModel);
                } else if (value is ActiveState) {
                  return _buildActive(context, value, viewModel);
                } else {
                  return _buildInactive(context);
                }
              }),
        ],
      );

  Widget _buildInactive(BuildContext context) => Center(
        child: const Text('Nothing is playing'),
      );

  Widget _buildActive(
    BuildContext context,
    ActiveState state,
    PlayerControlPanelViewModel viewModel, {
    double height = 50,
  }) =>
      LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            _songDetailWidget(state),

            const SizedBox(height: 16),

            // Play control
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ValueListenableBuilder(
                      valueListenable: state.isPlayingNotifier,
                      builder: (context, isPlaying, child) => IconButton(
                            icon: isPlaying
                                ? Icon(Icons.pause)
                                : Icon(Icons.play_arrow),
                            onPressed: () =>
                                viewModel.togglePlayPause(!isPlaying),
                          )),
                  IconButton(
                    icon: Icon(Icons.skip_next),
                    onPressed: () => viewModel.nextSong(),
                  ),
                  Spacer(),
                  ValueListenableBuilder(
                    valueListenable: viewModel.selectedPlayerItemNotifier,
                    builder: (context, playerItem, child) =>
                        _buildSelectedPlayerWidget(context, playerItem),
                  ),
                ],
              ),
            ),

            // Seek control
            ValueListenableBuilder(
              valueListenable: viewModel.currentSeekValueNotifier,
              builder: (context, value, child) => Slider(
                value: min(value, state.maxSeekValue),
                min: state.minSeekValue,
                max: state.maxSeekValue,
                onChanged: viewModel.updateSliderValue,
                onChangeStart: (_) => viewModel.toggleSeeking(true),
                onChangeEnd: (_) {
                  viewModel.toggleSeeking(false);
                  viewModel.seek(value);
                },
              ),
            ),

            // Volume control
            Container(
              width: constraints.maxWidth * 0.75,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.volume_up, color: Colors.grey),
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: viewModel.currentVolumeValueNotifier,
                      builder: (context, value, child) => Slider(
                        value: value,
                        min: state.minVolumeValue,
                        max: state.maxVolumeValue,
                        onChanged: viewModel.setVolume,
                        activeColor: Colors.grey,
                        inactiveColor: Colors.grey[300],
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );

  Widget _songDetailWidget(
    ActiveState state, {
    double height = 50,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(height / 2),
              child: Container(
                color: Colors.grey,
                height: height,
                width: height,
                child: CachedNetworkImage(
                  imageUrl: state.thumbnailURL.toString(),
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.music_note),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.title),
                  const SizedBox(width: 16),
                  Text(state.artist),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildSelectedPlayerWidget(BuildContext context, PlayerItem? player) =>
      InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        onTap: () => _showPlayerSelector(context, context.read()),
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              player?.name ?? "Select player",
              textAlign: TextAlign.left,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: TextDecoration.underline,
                  ),
            ),
          ),
        ),
      );

  void _showPlayerSelector(
      BuildContext context, PlayerControlPanelViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => context
          .read<AdminFeatureUIProvider>()
          .buildPlayerManagerDialog(viewModel.room),
    );
  }
}
