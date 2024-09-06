part of 'sessionfeature.dart';

class SessionView extends StatefulWidget {
  const SessionView({
    super.key,
    required this.viewModel,
  });

  final SessionViewModel viewModel;

  @override
  State<SessionView> createState() => _SessionViewState();
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
              title: const Text('Session'),
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              automaticallyImplyLeading: false,
            ),
            body: _buildBody(context, viewModel),
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
    return ValueListenableBuilder<List<SongItem>>(
      valueListenable: viewModel.songListNotifier,
      builder: (context, songList, child) {
        return ReorderableListView.builder(
          onReorder: (oldIndex, newIndex) {
            viewModel.reorderSongList(oldIndex, newIndex);
          },
          itemCount: songList.length,
          itemBuilder: (context, index) {
            final song = songList[index];
            return Slidable(
              key: Key(song.title),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) => viewModel.dismissSong(song),
                    backgroundColor:
                        song.currentPlaying ? Colors.blue : Colors.red,
                    foregroundColor: Colors.white,
                    icon: song.currentPlaying ? Icons.skip_next : Icons.cancel,
                    label: song.currentPlaying ? 'Skip' : 'Cancel',
                  ),
                  if (song.currentPlaying) ...[
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
                ],
              ),
              child: ListTile(
                leading: song.imageURL != null
                    ? Image.network(song.imageURL.toString())
                    : null,
                title: Text(song.title),
                subtitle: Text(song.artist),
                trailing: song.currentPlaying
                    ? Icon(Icons.play_arrow, color: Colors.green)
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
