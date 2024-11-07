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
        children: [
          ValueListenableBuilder(
              valueListenable: viewModel.stateNotifier,
              builder: (context, value, child) {
                if (value is ActiveState) {
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
        builder: (context, constraints) => Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
              Row(
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
                ],
              ),
              ValueListenableBuilder(
                valueListenable: viewModel.currentSeekValueNotifier,
                builder: (context, value, child) => Slider(
                  value: value,
                  min: state.minSeekValue,
                  max: state.maxSeekValue,
                  onChanged: viewModel.seek,
                  onChangeStart: (_) => viewModel.toggleSeeking(true),
                  onChangeEnd: (_) => viewModel.toggleSeeking(false),
                ),
              ),
              Container(
                width: constraints.maxWidth * 0.5,
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
        ),
      );
}
