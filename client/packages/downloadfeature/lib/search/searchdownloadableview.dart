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
  DownloadFlowCoordinator get coordinator => widget.coordinator;
  DownloadLocalizations get localizations => widget.localizations;
  DownloadAssets get assets => widget.assets;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.searchDownloadables();
      viewModel.submissionStateNotifier.addListener(_submissionResultListener);

      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _submissionResultListener() {
    final result = viewModel.submissionStateNotifier.value;

    if (result is IdentifySubmissionSuccess) {
      debugPrint('Identified song: ${result.identifiedSongDetails}');
      coordinator.navigateToIdentifiedSongDetailsView(
        context,
        details: result.identifiedSongDetails,
      );
    }

    if (result is IdentifySubmissionFailure) {
      final exception = result.exception;
      if (exception is DownloadException) {
        debugPrint("exception type: ${exception.type}");
        if (exception.type == ExceptionType.alreadyExists) {
          _showErrorDialog(context, exception, localizations);
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            exception.localizedFrom(localizations).localizedTextOf(context),
      ));
    }
  }

  void _showErrorDialog(BuildContext context, DownloadException exception,
      DownloadLocalizations localizations) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content:
              Text(exception.localizedFrom(localizations).localizedOf(context)),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Handle Cancel action
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle View action
                Navigator.of(context).pop();
              },
              child: Text('Reserve'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Consumer<SearchDownloadableViewModel>(
        builder: (context, viewModel, _) => Stack(
          children: [
            _buildScaffold(context, viewModel),
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
                }),
          ],
        ),
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
                viewModel.clearSearchQuery(),
                _searchFocusNode.requestFocus(),
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
            state.searchText.isNotEmpty
                ? assets.errorBannerImage.image(height: 200)
                : assets.identifySongBannerImage.image(height: 200),
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
                  Text("${item.duration} | ${item.artist}"),
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
          _searchFocusNode.unfocus();
          switch (value) {
            case 'identify':
              viewModel.identifyDownloadable(item);
              break;
            case 'preview':
              coordinator.previewDownloadable(context, item);
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
            state.exception.localizedFrom(localizations).localizedOf(context),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          TextButton(
            onPressed: () => viewModel.searchDownloadables(),
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
