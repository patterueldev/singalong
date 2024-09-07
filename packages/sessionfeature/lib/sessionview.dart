part of 'sessionfeature.dart';

class SessionView extends StatefulWidget
    implements SessionViewCallbackDelegate {
  const SessionView({
    super.key,
    required this.viewModel,
    required this.navigationDelegate,
  });

  final SessionViewModel viewModel;
  final SessionNavigationDelegate navigationDelegate;

  @override
  State<SessionView> createState() => _SessionViewState();

  @override
  void onAdded() {
    // viewModel.refresh();
  }

  @override
  void onCancel() {
    // viewModel.canceled();
  }
}

class _SessionViewState extends State<SessionView> {
  SessionViewModel get viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.setupSession();
    });
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              automaticallyImplyLeading: false,
            ),
            body: _buildBody(context, viewModel),
            floatingActionButton: FloatingActionButton(
              onPressed: () =>
                  widget.navigationDelegate.openSongBook(context, widget),
              child: const Icon(Icons.menu_book),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: viewModel.stateNotifier,
            builder: (context, state, child) => state is Loading
                ? Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          ValueListenableBuilder(
            valueListenable: viewModel.stateNotifier,
            builder: (context, state, child) {
              if (state is Failure) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                });
              }
              return const SizedBox.shrink();
            },
          ),
          ValueListenableBuilder(
            valueListenable: viewModel.promptNotifier,
            builder: (context, prompt, child) {
              if (prompt != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(prompt.title),
                      content: Text(prompt.message),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            prompt.onAction();
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                          child: Text(prompt.actionText),
                        ),
                      ],
                    ),
                  );
                });
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      );
  Widget _buildBody(BuildContext context, SessionViewModel viewModel) {
    return ValueListenableBuilder<List<ReservedSongItem>>(
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
                      label: 'Skip',
                    ),
                    // Pause
                    SlidableAction(
                      onPressed: (context) {
                        // Handle pause action
                        if (song.currentPlaying) {
                          // Pause logic here
                        }
                      },
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      icon: Icons.pause,
                      label: 'Pause',
                    ),
                  ],
                  if (!song.currentPlaying) ...[
                    // Play Next
                    SlidableAction(
                      onPressed: (context) =>
                          viewModel.reorderSongList(index, 1),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      icon: Icons.play_arrow,
                      label: 'Play Next',
                    ),
                    // Cancel
                    SlidableAction(
                      onPressed: (context) => viewModel.dismissSong(song),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.cancel,
                      label: 'Cancel',
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
                      imageUrl: song.imageURL.toString(),
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
                    Text('Reserved by: ${song.reservingUser}'),
                  ],
                ),
                trailing: song.currentPlaying
                    ? const Icon(Icons.play_arrow, color: Colors.green)
                    : null,
                onTap: null,
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
