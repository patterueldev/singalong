part of '../songbookfeature.dart';

abstract class SongBookViewModel {
  ValueNotifier<SongBookViewState> get stateNotifier;
  ValueNotifier<bool> get isSearchActive;
  ValueNotifier<bool> get isLoadingNotifier; // for the HUD overlay
  ValueNotifier<String?> get toastMessageNotifier;

  void fetchSongs(bool loadsNext);
  void toggleSearch();
  void updateSearchQuery(String query);
  void reserveSong(SongItem song);
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
  final ReserveSongUseCase reserveSongUseCase;

  DefaultSongBookViewModel({
    required this.fetchSongsUseCase,
    required this.reserveSongUseCase,
  }) {
    fetchSongs(false);
  }

  @override
  final ValueNotifier<SongBookViewState> stateNotifier =
      ValueNotifier<SongBookViewState>(SongBookViewState.initial());

  @override
  final ValueNotifier<bool> isSearchActive = ValueNotifier<bool>(false);

  @override
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  @override
  final ValueNotifier<String?> toastMessageNotifier =
      ValueNotifier<String?>(null);

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
  void reserveSong(SongItem song) async {
    isLoadingNotifier.value = true;
    final result = await reserveSongUseCase(song).run();
    result.fold(
      (exception) {
        isLoadingNotifier.value = false;
        stateNotifier.value = SongBookViewState.failure(exception.message);
      },
      (_) {
        isLoadingNotifier.value = false;
        // maybe show a toast
        toastMessageNotifier.value = 'Song reserved';
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
