part of '../songbookfeature.dart';

class SongBookView extends StatefulWidget {
  const SongBookView({
    super.key,
    required this.viewModel,
    required this.navigationCoordinator,
    required this.localizations,
    required this.assets,
  });

  final SongBookViewModel viewModel;
  final SongBookFlowCoordinator navigationCoordinator;
  final SongBookLocalizations localizations;
  final SongBookAssets assets;
  @override
  State<SongBookView> createState() => _SongBookViewState();
}

class _SongBookViewState extends State<SongBookView> {
  SongBookViewModel get viewModel => widget.viewModel;
  SongBookFlowCoordinator get navigationCoordinator =>
      widget.navigationCoordinator;
  SongBookLocalizations get localizations => widget.localizations;
  SongBookAssets get assets => widget.assets;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.fetchSongs(false);
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
                onPressed: () => {
                  if (isSearching) _searchController.clear(),
                  viewModel.toggleSearch(),
                },
              ),
            ),
          ],
        ),
        body: Container(
          padding: const EdgeInsets.all(20),
          color: Colors.grey[200],
          child: ValueListenableBuilder<SongBookViewState>(
            valueListenable: viewModel.stateNotifier,
            builder: (context, state, child) {
              switch (state.type) {
                case SongBookViewStateType.initial:
                case SongBookViewStateType.loading:
                case SongBookViewStateType.loaded:
                  List<SongItem> songList = [];
                  bool isLoading = false;
                  if (state is Loading) {
                    songList = state.songList;
                    isLoading = true;
                  } else if (state is Loaded) {
                    songList = state.songList;
                  }
                  return _buildSongList(songList, isLoading);

                case SongBookViewStateType.empty:
                  final emptyState = state as Empty;
                  return _buildEmpty(emptyState);

                case SongBookViewStateType.failure:
                  final failureState = state as Failure;
                  return _buildError(failureState);
              }
            },
          ),
        ),
      );

  Widget _buildEmpty(Empty state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 150),
          assets.errorBannerImage.image(
            height: 200,
          ),
          state.localizedFrom(localizations).localizedTextOf(
                context,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
          TextButton(
            onPressed: () =>
                widget.navigationCoordinator.openDownloadScreen(context),
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
      );

  Widget _buildSongList(List<SongItem> songList, bool isLoading) =>
      Skeletonizer(
        enabled: isLoading,
        child: ListView.builder(
          itemCount: songList.length,
          itemBuilder: (context, index) {
            final song = songList[index];
            return Card(
              child: ListTile(
                title: Text(song.title),
                subtitle: Text(song.artist),
                leading: Image.network(song.thumbnailURL),
                trailing: song.alreadyPlayed
                    ? const Icon(Icons.music_note_sharp)
                    : null,
              ),
            );
          },
        ),
      );

  Widget _buildError(Failure state) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          assets.errorBannerImage.image(),
          Text(
            state.error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          TextButton(
            onPressed: () => viewModel.fetchSongs(true),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh),
                const SizedBox(width: 8),
                Text("Retry"),
              ],
            ),
          ),
        ],
      );
}
