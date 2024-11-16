part of '../adminfeature.dart';

class ReservedPanelWidget extends StatelessWidget {
  const ReservedPanelWidget();

  @override
  Widget build(BuildContext context) => Consumer<ReservedPanelViewModel>(
        builder: (context, viewModel, child) => Scaffold(
          appBar: AppBar(
            title: const Text("Reserved Songs"),
            leading: IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => {},
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.menu_book),
                onPressed: () => {},
              ),
            ],
          ),
          body: _buildBody(context, viewModel),
        ),
      );

  Widget _buildBody(BuildContext context, ReservedPanelViewModel viewModel) {
    return ValueListenableBuilder(
      valueListenable: viewModel.songListNotifier,
      builder: (context, songList, child) {
        return ListView.builder(
          itemCount: songList.length,
          itemBuilder: (context, index) {
            final song = songList[index];
            return Slidable(
              key: Key(song.title),
              startActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  if (song.currentPlaying) ...[
                    // Skip
                    SlidableAction(
                      onPressed: (context) => viewModel.dismissSong(song),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      icon: Icons.skip_next,
                      label: "Skip",
                    ),
                  ],
                  if (!song.currentPlaying) ...[
                    // Play Next
                    SlidableAction(
                      onPressed: (context) => {},
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      icon: Icons.play_arrow,
                      label: "Play Next",
                    ),
                    // Cancel
                    SlidableAction(
                      onPressed: (context) => viewModel.dismissSong(song),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.cancel,
                      label: "Cancel",
                    ),
                  ],
                ],
              ),
              child: ListTile(
                leading: Container(
                  width: 50.0, // Set a fixed width for the image container
                  height: 50.0, // Set a fixed height for the image container
                  decoration: BoxDecoration(
                    color: Colors.grey, // Set the background color to grey
                    borderRadius: BorderRadius.circular(
                        8.0), // Optional: Add border radius
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                        8.0), // Optional: Match border radius
                    child: CachedNetworkImage(
                      imageUrl: song.thumbnailURL.toString(),
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.music_note),
                      fit:
                          BoxFit.cover, // Ensure the image covers the container
                    ),
                  ),
                ),
                title: Text(song.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.artist),
                    Text("Reserved by ${song.reservingUser}"),
                  ],
                ),
                trailing: song.currentPlaying
                    ? const Icon(Icons.play_arrow, color: Colors.green)
                    : null,
                onTap: () => {},
              ),
            );
          },
        );
      },
    );
  }
}
