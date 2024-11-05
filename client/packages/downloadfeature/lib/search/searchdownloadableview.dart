part of '../downloadfeature.dart';

class SearchDownloadableView extends StatefulWidget {
  const SearchDownloadableView({
    super.key,
    required this.coordinator,
    required this.localizations,
    required this.assets,
  });

  final DownloadFlowCoordinator coordinator;
  final DownloadLocalizations localizations;
  final DownloadAssets assets;

  @override
  State<StatefulWidget> createState() => _SearchDownloadableViewState();
}

class _SearchDownloadableViewState extends State<SearchDownloadableView> {
  SearchDownloadableViewModel get viewModel =>
      Provider.of<SearchDownloadableViewModel>(context, listen: false);
  DownloadFlowCoordinator get navigationCoordinator => widget.coordinator;
  DownloadLocalizations get localizations => widget.localizations;
  DownloadAssets get assets => widget.assets;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.searchDownloadables(false);
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Consumer<SearchDownloadableViewModel>(
        builder: (context, viewModel, _) => _buildScaffold(context, viewModel),
      );

  Widget _buildScaffold(
          BuildContext context, SearchDownloadableViewModel viewModel) =>
      Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: TextField(
            autocorrect: false,
            controller: viewModel.searchController,
            focusNode: _searchFocusNode,
            onChanged: viewModel.updateSearchQuery,
            decoration: InputDecoration(
              hintText: "Search",
              border: InputBorder.none,
              fillColor: Colors.grey,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => {
                viewModel.searchController.clear(),
              },
            ),
          ],
        ),
        body: Container(
          padding: const EdgeInsets.all(20),
          child: ValueListenableBuilder<SearchDownloadableViewState>(
            valueListenable: viewModel.stateNotifier,
            builder: (context, state, child) {
              debugPrint('SongBookViewState: $state');
              switch (state.type) {
                case SearchDownloadableViewStateType.initial:
                case SearchDownloadableViewStateType.loading:
                case SearchDownloadableViewStateType.loaded:
                  List<DownloadableItem> downloadableList = [];
                  bool isLoading = false;
                  if (state is Loading) {
                    downloadableList = state.downloadableList;
                    isLoading = true;
                  } else if (state is Loaded) {
                    downloadableList = state.downloadableList;
                  }
                  debugPrint('Downloadable list: $downloadableList');
                  return _buildList(downloadableList, viewModel, isLoading);

                case SearchDownloadableViewStateType.notFound:
                  final emptyState = state as NotFound;
                  return _buildEmpty(emptyState);

                case SearchDownloadableViewStateType.failure:
                  final failureState = state as Failure;
                  return _buildError(failureState, viewModel);
              }
            },
          ),
        ),
      );

  Widget _buildEmpty(NotFound state) => SingleChildScrollView(
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
                  widget.coordinator.navigateToURLIdentifierView(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.download),
                  const SizedBox(width: 8),
                  localizations.searchByURL.localizedTextOf(context),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildList(List<DownloadableItem> downloadableList,
          SearchDownloadableViewModel viewModel, bool isLoading,
          {double height = 50}) =>
      Skeletonizer(
        enabled: isLoading,
        child: ListView.builder(
          itemCount: downloadableList.length,
          itemBuilder: (context, index) => Card(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildItem(downloadableList[index], viewModel, height),
            ),
          ),
        ),
      );

  Widget _buildItem(DownloadableItem item,
          SearchDownloadableViewModel viewModel, double height) =>
      _popupButton(
        item,
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
                  imageUrl: item.thumbnailURL.toString(),
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
                  Text(item.title),
                  const SizedBox(width: 16),
                  Text(item.artist),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _popupButton(DownloadableItem item,
          SearchDownloadableViewModel viewModel, Widget child) =>
      PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'identify':
              viewModel.identifyDownloadable(item);
              break;
            case 'preview':
              navigationCoordinator.previewDownloadable(context, item);
              break;
          }
        },
        itemBuilder: (BuildContext context) => const [
          PopupMenuItem<String>(
            value: 'identify',
            child: Text("Identify"),
          ),
          PopupMenuItem<String>(
            value: 'preview',
            child: Text("Preview"),
          ),
        ],
        child: child,
      );

  Widget _buildError(Failure state, SearchDownloadableViewModel viewModel) =>
      Column(
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
            onPressed: () => viewModel.searchDownloadables(false),
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
