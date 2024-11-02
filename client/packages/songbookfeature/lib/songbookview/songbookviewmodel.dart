part of '../songbookfeature.dart';

abstract class SongBookViewModel {
  ValueNotifier<SongBookViewState> get stateNotifier;
  ValueNotifier<bool> get isSearchActive;

  void fetchSongs(bool loadsNext);
  void toggleSearch();
  void updateSearchQuery(String query);
}

class SongBookException extends GenericException {
  final String message;

  SongBookException(this.message);

  // TODO: Can't really figure out what to throw for now;
  // for now, it's just the generic unknown error/unhandled exception
  // this will be updated later
}

class DefaultSongBookViewModel extends SongBookViewModel {
  final FetchSongsUseCase fetchSongsUseCase;

  DefaultSongBookViewModel({
    required this.fetchSongsUseCase,
  }) {
    fetchSongs(false);
  }

  @override
  final ValueNotifier<SongBookViewState> stateNotifier =
      ValueNotifier<SongBookViewState>(SongBookViewState.initial());

  @override
  final ValueNotifier<bool> isSearchActive = ValueNotifier<bool>(false);

  String? _searchQuery;
  Timer? _searchDebounce;

  Pagination? nextPage;

  @override
  void fetchSongs(bool loadsNext) async {
    stateNotifier.value = SongBookViewState.loading();
    final parameters = LoadSongsParameters.next(
      keyword: _searchQuery,
      limit: 10,
      nextPage: loadsNext ? nextPage : null,
    );
    final result = await fetchSongsUseCase(parameters).run();
    result.fold(
      (exception) {
        stateNotifier.value = SongBookViewState.failure(exception.message);
      },
      (fetchSongResult) {
        final songList = fetchSongResult.songs;
        nextPage = fetchSongResult.next();
        if (songList.isEmpty) {
          stateNotifier.value =
              SongBookViewState.empty(searchText: _searchQuery ?? '');
        } else {
          final state = stateNotifier.value;
          if (state is Loaded) {
            final currentSongs = state.songList;
            songList.insertAll(0, currentSongs);
          }
          stateNotifier.value = SongBookViewState.loaded(songList);
        }
      },
    );
  }

  @override
  void toggleSearch() {
    isSearchActive.value = !isSearchActive.value;
    if (!isSearchActive.value) {
      _searchQuery = null;
      fetchSongs(false);
    }
  }

  @override
  void updateSearchQuery(String query) {
    if (_searchQuery == query) return;
    Duration debounceTime;
    if (query.isEmpty) {
      _searchQuery = null;
      debounceTime = const Duration(milliseconds: 0);
    } else {
      _searchQuery = query;
      debounceTime = const Duration(milliseconds: 500);
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(debounceTime, () => fetchSongs(false));
  }
}
