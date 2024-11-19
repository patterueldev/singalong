part of '../adminfeature.dart';

class SongBookManagerDialog extends StatelessWidget {
  final AdminCoordinator navigationCoordinator;
  const SongBookManagerDialog({super.key, required this.navigationCoordinator});

  @override
  Widget build(BuildContext context) => Consumer<SongBookManagerViewModel>(
        builder: (context, viewModel, child) => Dialog(
          child: Column(
            children: [
              const Text("Edit Song"),
              Expanded(
                child: ListView.builder(
                  itemCount: viewModel.songListNotifier.value.length,
                  itemBuilder: (context, index) {
                    final song = viewModel.songListNotifier.value[index];
                    return ListTile(
                      title: Text(song.title),
                      subtitle: Text(song.artist),
                      leading: Image.network(song.thumbnailURL),
                      trailing: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => viewModel.reserveSong(song),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
}
