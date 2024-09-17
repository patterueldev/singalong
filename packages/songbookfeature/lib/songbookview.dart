part of 'songbookfeature.dart';

class SongBookView extends StatefulWidget {
  const SongBookView({
    super.key,
    required this.viewModel,
    required this.navigationCoordinator,
    required this.localizations,
  });

  final SongBookViewModel viewModel;
  final SongBookNavigationCoordinator navigationCoordinator;
  final SongBookLocalizations localizations;
  @override
  State<SongBookView> createState() => _SongBookViewState();
}

class _SongBookViewState extends State<SongBookView> {
  SongBookViewModel get viewModel => widget.viewModel;
  SongBookNavigationCoordinator get navigationCoordinator =>
      widget.navigationCoordinator;
  SongBookLocalizations get localizations => widget.localizations;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.fetchSongs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: ValueListenableBuilder<bool>(
            valueListenable: viewModel.isSearchActive,
            builder: (context, isSearching, child) {
              if (isSearching) {
                // Request focus when search is active
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _searchFocusNode.requestFocus();
                });
              }
              return isSearching
                  ? TextField(
                      autocorrect: false,
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: viewModel.updateSearchQuery,
                      decoration: InputDecoration(
                        hintText: localizations.searchHint.localizedOf(context),
                        border: InputBorder.none,
                        fillColor: Colors.grey,
                      ),
                      style: const TextStyle(color: Colors.black),
                    )
                  : Text(
                      localizations.songBookScreenTitle.localizedOf(context));
            },
          ),
          actions: [
            // cancel search
            ValueListenableBuilder<bool>(
              valueListenable: viewModel.isSearchActive,
              builder: (context, isSearching, child) => IconButton(
                icon: isSearching
                    ? const Icon(Icons.close)
                    : const Icon(Icons.search),
                onPressed: () => viewModel.toggleSearch(),
              ),
            ),
          ],
        ),
        body: Container(
          padding: EdgeInsets.all(20),
          color: Colors.grey[200],
          child: ValueListenableBuilder<SongBookViewState>(
            valueListenable: viewModel.stateNotifier,
            builder: (context, state, child) {
              bool isLoading = false;
              List<SongItem> songList = [];
              String? searchQuery;
              switch (state.type) {
                case SongBookViewStateType.loading:
                  isLoading = true;
                  songList = (state as Loading).songList;
                  break;
                case SongBookViewStateType.loaded:
                  final loadedState = state as Loaded;
                  songList = loadedState.songList;
                  searchQuery = loadedState.searchQuery;
                  break;
                case SongBookViewStateType.failure:
                  return Center(
                    child: Text((state as Failure).error),
                  );
                default:
                  break;
              }
              return Skeletonizer(
                enabled: isLoading,
                child: songList.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            searchQuery == null
                                ? localizations.emptySongBook
                                    .localizedOf(context)
                                : localizations
                                    .songNotFound(searchQuery)
                                    .localizedOf(context),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          TextButton(
                            onPressed: () => widget.navigationCoordinator
                                .openDownloadScreen(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.download),
                                const SizedBox(width: 8),
                                Text(
                                  localizations.download.localizedOf(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: songList.length,
                        itemBuilder: (context, index) {
                          final song = songList[index];
                          return Card(
                            child: ListTile(
                              title: Text(song.title),
                              subtitle: Text(song.artist),
                              leading: Image.network(song.imageURL),
                              trailing: song.alreadyPlayed
                                  ? const Icon(Icons.music_note_sharp)
                                  : null,
                            ),
                          );
                        },
                      ),
              );
            },
          ),
        ),
      );
}
