part of '../adminfeature.dart';

class PlayerManagerWidget extends StatelessWidget {
  const PlayerManagerWidget({
    super.key,
    required this.coordinator,
  });

  final AdminCoordinator coordinator;

  @override
  Widget build(BuildContext context) => Consumer<PlayerManagerViewModel>(
        builder: (context, viewModel, child) => Stack(
          children: [
            Expanded(child: _buildList(context, viewModel)),
            ValueListenableBuilder(
                valueListenable: viewModel.isLoadingNotifier,
                builder: (context, isLoading, child) {
                  if (isLoading) {
                    return Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
          ],
        ),
      );

  Widget _buildList(BuildContext context, PlayerManagerViewModel viewModel) =>
      ValueListenableBuilder(
          valueListenable: viewModel.playersNotifier,
          builder: (context, players, child) => ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];
                  return ListTile(
                    title: Text(player.name),
                    subtitle: Text(player.id),
                    trailing: player.isIdle
                        ? const Icon(Icons.pause)
                        : const Icon(Icons.play_arrow),
                  );
                },
              ));

  Widget _buildPlayerItem(BuildContext context, PlayerItem player) => InkWell(
        onTap: () => {},
        child: Column(
          children: [
            Text(player.name),
            Text(player.id),
            player.isIdle
                ? const Icon(Icons.pause)
                : const Icon(Icons.play_arrow),
          ],
        ),
      );
}
