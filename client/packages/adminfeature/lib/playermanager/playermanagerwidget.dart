part of '../adminfeature.dart';

class PlayerSelectorDialogWidget extends StatelessWidget {
  const PlayerSelectorDialogWidget({super.key});

  @override
  Widget build(BuildContext context) => Consumer<PlayerSelectorViewModel>(
        builder: (context, viewModel, child) => Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.5),
                child: Dialog(
                  child: _buildList(context, viewModel),
                ),
              ),
            ),
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
            ValueListenableBuilder(
                valueListenable: viewModel.onAssignedRoom,
                builder: (context, onAssignedRoom, child) {
                  if (onAssignedRoom != null) {
                    Navigator.of(context).pop(onAssignedRoom);
                  }
                  return const SizedBox.shrink();
                }),
          ],
        ),
      );

  Widget _buildList(BuildContext context, PlayerSelectorViewModel viewModel) =>
      ValueListenableBuilder(
          valueListenable: viewModel.playersNotifier,
          builder: (context, players, child) => ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) =>
                    _buildPlayerItem(context, players[index]),
              ));

  Widget _buildPlayerItem(BuildContext context, PlayerItem player) => InkWell(
        onTap: () =>
            context.read<PlayerSelectorViewModel>().selectPlayer(player),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
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
