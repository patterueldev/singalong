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
        ],
      );

  Widget _buildBody(BuildContext context, SessionViewModel viewModel) =>
      ValueListenableBuilder<List<SongItem>>(
        valueListenable: viewModel.songListNotifier,
        builder: (context, songList, child) {
          return ListView.builder(
            itemCount: songList.length,
            itemBuilder: (context, index) {
              final song = songList[index];
              return ListTile(
                leading: song.imageURL != null
                    ? Image.network(song.imageURL.toString())
                    : null,
                title: Text(song.title),
                subtitle: Text(song.artist),
                trailing: song.currentPlaying
                    ? Icon(Icons.play_arrow, color: Colors.green)
                    : null,
                onTap: () {
                  // Handle song item tap
                },
              );
            },
          );
        },
      );

  @override
  void dispose() {
    super.dispose();
  }
}
