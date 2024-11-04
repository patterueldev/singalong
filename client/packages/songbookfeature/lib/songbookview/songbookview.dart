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
      viewModel.toastMessageNotifier.addListener(_toastListener);
    });
  }

  void _toastListener() {
    final message = viewModel.toastMessageNotifier.value;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
      ));
      viewModel.toastMessageNotifier.value = null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          _buildScaffold(context),
          ValueListenableBuilder(
            valueListenable: viewModel.isLoadingNotifier,
            builder: (context, isLoading, child) {
              if (isLoading) {
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

  Widget _buildScaffold(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          child: ValueListenableBuilder<SongBookViewState>(
            valueListenable: viewModel.stateNotifier,
            builder: (context, state, child) {
              debugPrint('SongBookViewState: $state');
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

  Widget _buildEmpty(Empty state) => SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 150),
            assets.errorBannerImage.image(height: 200),
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
        ),
      );

  Widget _buildSongList(List<SongItem> songList, bool isLoading,
          {double height = 50}) =>
      Skeletonizer(
        enabled: isLoading,
        child: ListView.builder(
          itemCount: songList.length,
          itemBuilder: (context, index) => Card(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildItem(songList[index], height),
            ),
          ),
        ),
      );

  Widget _buildItem(SongItem song, double height) => _popupButton(
        song,
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(height / 2),
              child: Container(
                color: Colors.grey,
                height: height,
                width: height,
                child: CachedNetworkImage(
                  imageUrl: song.thumbnailURL.toString(),
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.music_note),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(song.title),
                  const SizedBox(width: 16),
                  Text(song.artist),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _popupButton(SongItem song, Widget child) => PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'reserve':
              viewModel.reserveSong(song);
              break;
            case 'details':
              navigationCoordinator.openSongDetailScreen(context, song);
              break;
          }
        },
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem<String>(
              value: 'reserve',
              child: Text("Reserve Song"),
            ),
            PopupMenuItem<String>(
              value: 'details',
              child: Text("View Details"),
            ),
          ];
        },
        child: child,
      );

  Widget _buildError(Failure state) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          assets.errorBannerImage.image(height: 100),
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
