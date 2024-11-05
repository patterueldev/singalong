part of '../downloadfeature.dart';

abstract class SearchDownloadableViewModel extends ChangeNotifier {
  TextEditingController searchController = TextEditingController();
  ValueNotifier<SearchDownloadableViewState> stateNotifier =
      ValueNotifier(SearchDownloadableViewState.initial());
  ValueNotifier<bool> isLoadingNotifier =
      ValueNotifier(false); // for the HUD overlay
  ValueNotifier<String?> toastMessageNotifier = ValueNotifier(null);
  ValueNotifier<IdentifySubmissionState> submissionStateNotifier =
      ValueNotifier(IdentifySubmissionState.idle());

  void searchDownloadables();
  void updateSearchQuery(String query,
      {Duration debounceTime = const Duration(milliseconds: 500)});
  void identifyDownloadable(DownloadableItem downloadable);
}

class DefaultSearchDownloadableViewModel extends SearchDownloadableViewModel {
  final SearchDownloadableSongUseCase searchDownloadableSongUseCase;
  final IdentifySongUrlUseCase identifySongUrlUseCase;
  DefaultSearchDownloadableViewModel({
    required this.searchDownloadableSongUseCase,
    required this.identifySongUrlUseCase,
    this.searchQuery = '',
  }) {
    searchController.text = searchQuery;
  }

  String searchQuery;
  Timer? _searchDebounce;

  @override
  void searchDownloadables() async {
    stateNotifier.value = SearchDownloadableViewState.loading();

    final result = await searchDownloadableSongUseCase(searchQuery).run();
    result.fold(
      (exception) {
        stateNotifier.value = SearchDownloadableViewState.failure(exception);
      },
      (downloadables) {
        if (downloadables.isEmpty) {
          stateNotifier.value =
              SearchDownloadableViewState.notFound(searchText: searchQuery);
        } else {
          stateNotifier.value =
              SearchDownloadableViewState.loaded(downloadables);
        }
      },
    );
  }

  @override
  void identifyDownloadable(DownloadableItem downloadable) async {
    isLoadingNotifier.value = true;

    final url = downloadable.sourceUrl;
    final result = await identifySongUrlUseCase(url).run();

    result.fold(
      (exception) {
        submissionStateNotifier.value =
            IdentifySubmissionState.failure(exception);
      },
      (details) {
        submissionStateNotifier.value =
            IdentifySubmissionState.success(details);
      },
    );
    isLoadingNotifier.value = false;
  }

  @override
  void updateSearchQuery(
    String query, {
    Duration debounceTime = const Duration(milliseconds: 500),
  }) {
    if (searchQuery == query) return;
    searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(debounceTime, () => searchDownloadables());
  }
}
