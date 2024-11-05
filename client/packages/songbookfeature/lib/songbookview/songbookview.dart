part of '../songbookfeature.dart';

class SongBookView extends StatefulWidget {
  const SongBookView({
    super.key,
    required this.navigationCoordinator,
    required this.localizations,
    required this.assets,
  });

  final SongBookFlowCoordinator navigationCoordinator;
  final SongBookLocalizations localizations;
  final SongBookAssets assets;
  @override
  State<SongBookView> createState() => _SongBookViewState();
}

class _SongBookViewState extends State<SongBookView> {
  SongBookViewModel get viewModel =>
      Provider.of<SongBookViewModel>(context, listen: false);
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
  Widget build(BuildContext context) => Consumer<SongBookViewModel>(
        builder: (context, viewModel, _) => _buildScaffold(context, viewModel),
      );

  Widget _buildScaffold(BuildContext context, SongBookViewModel viewModel) =>
      Scaffold(
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
                      onSubmitted: (query) {
                        viewModel.updateSearchQuery(query);
                        viewModel.fetchSongs(false);
                      },
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
                  return _buildSongList(songList, viewModel, isLoading);

                case SongBookViewStateType.notFound:
                  final emptyState = state as NotFound;
                  return _buildEmpty(emptyState);

                case SongBookViewStateType.urlDetected:
                  final urlDetectedState = state as URLDetected;
                  return _buildURLDetected(urlDetectedState);

                case SongBookViewStateType.failure:
                  final failureState = state as Failure;
                  return _buildError(failureState, viewModel);
              }
            },
          ),
        ),
      );

  Widget _buildEmpty(NotFound state) => SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 50),
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
              onPressed: () => widget.navigationCoordinator
                  .openSearchDownloadablesScreen(context,
                      query: state.searchText),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search),
                  const SizedBox(width: 8),
                  localizations.search.localizedTextOf(context),
                ],
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
                  localizations.download.localizedTextOf(context),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildURLDetected(URLDetected state) => SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 150),
            assets.identifySongBannerImage.image(height: 200),
            state.localizedFrom(localizations).localizedTextOf(
                  context,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
            TextButton(
              onPressed: () => widget.navigationCoordinator
                  .openDownloadScreen(context, url: state.url),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search),
                  const SizedBox(width: 8),
                  localizations.continueIdentifyButtonText
                      .localizedTextOf(context),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildSongList(
          List<SongItem> songList, SongBookViewModel viewModel, bool isLoading,
          {double height = 50}) =>
      Skeletonizer(
        enabled: isLoading,
        child: ListView.builder(
          itemCount: songList.length,
          itemBuilder: (context, index) => Card(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildItem(songList[index], viewModel, height),
            ),
          ),
        ),
      );

  Widget _buildItem(
          SongItem song, SongBookViewModel viewModel, double height) =>
      _popupButton(
        song,
        viewModel,
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

  Widget _popupButton(
          SongItem song, SongBookViewModel viewModel, Widget child) =>
      PopupMenuButton<String>(
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
        itemBuilder: (BuildContext context) => const [
          PopupMenuItem<String>(
            value: 'reserve',
            child: Text("Reserve Song"),
          ),
          PopupMenuItem<String>(
            value: 'details',
            child: Text("View Details"),
          ),
        ],
        child: child,
      );

  Widget _buildError(Failure state, SongBookViewModel viewModel) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          assets.errorBannerImage.image(height: 100),
          Text(
            state.exception.localizedFrom(localizations).localizedOf(context),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          TextButton(
            onPressed: () => viewModel.fetchSongs(false),
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
