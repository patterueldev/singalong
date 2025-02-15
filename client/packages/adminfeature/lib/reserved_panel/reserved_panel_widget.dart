part of '../adminfeature.dart';

class ReservedPanelWidget extends StatelessWidget {
  final AdminCoordinator coordinator;
  const ReservedPanelWidget({super.key, required this.coordinator});

  @override
  Widget build(BuildContext context) => Consumer<ReservedPanelViewModel>(
        builder: (context, viewModel, child) => Scaffold(
          appBar: AppBar(
            title: const Text("Reserved Songs"),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
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
            return PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'details') {
                  coordinator.openSongDetailScreen(context, song.songId);
                } else if (value == 'skip') {
                  viewModel.nextSong();
                } else if (value == 'cancel') {
                  viewModel.cancelReservation(song.id);
                } else if (value == 'play-next') {
                  viewModel.moveUp(song.id);
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem<String>(
                    value: 'details',
                    child: Text("Details"),
                  ),
                  if (song.currentPlaying) ...[
                    PopupMenuItem<String>(
                      value: 'skip',
                      child: Text("Skip"),
                    ),
                  ],
                  if (!song.currentPlaying) ...[
                    PopupMenuItem<String>(
                      value: 'cancel',
                      child: Text("Cancel"),
                    ),
                    PopupMenuItem<String>(
                      value: 'move-up',
                      child: Text("Move Up"),
                    ),
                  ],
                ];
              },
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
              ),
            );
          },
        );
      },
    );
  }
}
