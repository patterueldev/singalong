part of '../downloadfeature.dart';

abstract class SearchDownloadableViewModel extends ChangeNotifier {
  TextEditingController searchController = TextEditingController();
  ValueNotifier<SearchDownloadableViewState> stateNotifier =
      ValueNotifier(SearchDownloadableViewState.initial());
  ValueNotifier<bool> isLoadingNotifier =
      ValueNotifier(false); // for the HUD overlay
  ValueNotifier<String?> toastMessageNotifier = ValueNotifier(null);

  void searchDownloadables(bool loadsNext);
  void updateSearchQuery(String query);
  void identifyDownloadable(DownloadableItem downloadable);
}

class DefaultSearchDownloadableViewModel extends SearchDownloadableViewModel {
  DefaultSearchDownloadableViewModel({
    String query = '',
  }) {
    _searchQuery = query;
    searchController.text = query;
  }

  String _searchQuery = '';
  Timer? _searchDebounce;

  Pagination? nextPage;

  List<DownloadableItem> _downloadables = []; // Replace with your song model

  void _filterSongs(String query) {
    final filtered = _downloadables.where((song) {
      final titleLower = song.title.toLowerCase();
      final artistLower = song.artist.toLowerCase();
      final searchLower = query.toLowerCase();

      return titleLower.contains(searchLower) ||
          artistLower.contains(searchLower);
    }).toList();

    stateNotifier.value = filtered.isEmpty
        ? SearchDownloadableViewState.loaded(_downloadables)
        : SearchDownloadableViewState.loaded(filtered);

    final state = stateNotifier.value;
    if (state is Loaded) {
      debugPrint('Downloadable list: ${state.downloadableList}');
    }
  }

  @override
  void searchDownloadables(bool loadsNext) {
    if (_searchQuery.isEmpty) {
      stateNotifier.value = SearchDownloadableViewState.initial();
      return;
    }

    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce?.cancel();
    }

    _downloadables = getSongs();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _filterSongs(_searchQuery);
    });
  }

  @override
  void identifyDownloadable(DownloadableItem downloadable) {
    // Do something with the downloadable
  }

  @override
  void updateSearchQuery(String query) {
    if (_searchQuery == query) return;
    Duration debounceTime;
    _searchQuery = query;
    debounceTime = const Duration(milliseconds: 500);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(debounceTime, () => searchDownloadables(false));
  }
}
