part of 'songbookfeature.dart';

class SongBookView extends StatefulWidget {
  const SongBookView({
    super.key,
    required this.viewModel,
    required this.localizations,
  });

  final SongBookViewModel viewModel;
  final SongBookLocalizations localizations;
  @override
  State<SongBookView> createState() => _SongBookViewState();
}

class _SongBookViewState extends State<SongBookView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.fetchSongs();
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
            valueListenable: widget.viewModel.isSearchActive,
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
                      onChanged: widget.viewModel.updateSearchQuery,
                      decoration: InputDecoration(
                        hintText: widget.localizations.searchHint
                            .localizedOf(context),
                        border: InputBorder.none,
                        fillColor: Colors.grey,
                      ),
                      style: const TextStyle(color: Colors.black),
                    )
                  : Text(widget.localizations.songBookScreenTitle
                      .localizedOf(context));
            },
          ),
          actions: [
            // cancel search
            ValueListenableBuilder<bool>(
              valueListenable: widget.viewModel.isSearchActive,
              builder: (context, isSearching, child) => IconButton(
                icon: isSearching
                    ? const Icon(Icons.close)
                    : const Icon(Icons.search),
                onPressed: () => widget.viewModel.toggleSearch(),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.grey[200],
                child: ValueListenableBuilder<SongBookViewState>(
                  valueListenable: widget.viewModel.stateNotifier,
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
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    searchQuery == null
                                        ? widget.localizations.emptySongBook
                                            .localizedOf(context)
                                        : widget.localizations
                                            .songNotFound(searchQuery)
                                            .localizedOf(context),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: widget.viewModel.fetchSongs,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.download),
                                        const SizedBox(width: 8),
                                        Text(
                                          widget.localizations.download
                                              .localizedOf(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
            ),
          ],
        ),
      );
}
