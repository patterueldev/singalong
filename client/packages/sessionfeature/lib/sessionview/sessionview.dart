part of '../sessionfeature.dart';

class SessionView extends StatefulWidget {
  const SessionView({
    super.key,
    required this.viewModel,
    required this.flow,
    required this.localizations,
  });

  final SessionViewModel viewModel;
  final SessionFlowCoordinator flow;
  final SessionLocalizations localizations;

  @override
  State<SessionView> createState() => _SessionViewState();
}

class _SessionViewState extends State<SessionView> {
  SessionViewModel get viewModel => widget.viewModel;
  SessionLocalizations get localizations => widget.localizations;
  SessionFlowCoordinator get flow => widget.flow;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.setupSession();
      viewModel.stateNotifier.addListener(_stateListener);
    });
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              leading: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'disconnect') {
                    viewModel.disconnect();
                  }
                },
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem<String>(
                      value: 'disconnect',
                      child: localizations.disconnectButtonText
                          .localizedTextOf(context),
                    ),
                  ];
                },
                icon: const Icon(Icons.menu),
              ),
            ),
            body: _buildBody(context, viewModel),
            floatingActionButton: FloatingActionButton(
              onPressed: () => widget.flow.onSongBook(context),
              child: const Icon(Icons.menu_book),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: viewModel.stateNotifier,
            builder: (context, state, child) {
              if (state.status == SessionViewStatus.loading) {
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
                      label: localizations.skipButtonText.localizedOf(context),
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
                      label: localizations.pauseButtonText.localizedOf(context),
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
                      label:
                          localizations.playNextButtonText.localizedOf(context),
                    ),
                    // Cancel
                    SlidableAction(
                      onPressed: (context) => viewModel.dismissSong(song),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.cancel,
                      label:
                          localizations.cancelButtonText.localizedOf(context),
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
                    localizations
                        .reservedByText(song.reservingUser)
                        .localizedTextOf(context),
                  ],
                ),
                trailing: song.currentPlaying
                    ? const Icon(Icons.play_arrow, color: Colors.green)
                    : null,
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.90,
                    child: SongView(
                      viewModel: DefaultSongViewModel(songId: song.songId),
                      localizations: localizations,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _stateListener() {
    final state = viewModel.stateNotifier.value;
    if (state is SessionFailure) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      });
    }
    if (state.status == SessionViewStatus.disconnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        flow.onDisconnected(context);
      });
    }
  }

  void _promptListener() {
    final prompt = viewModel.promptNotifier.value;
    if (prompt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: prompt.title.localizedTextOf(context),
            content: prompt.message.localizedTextOf(context),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: localizations.cancelButtonText.localizedTextOf(context),
              ),
              TextButton(
                onPressed: () {
                  prompt.onAction();
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: prompt.actionText.localizedTextOf(context),
              ),
            ],
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
