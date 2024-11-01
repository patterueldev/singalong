part of '../songbookfeature.dart';

abstract class SongBookViewModel {
  ValueNotifier<SongBookViewState> get stateNotifier;
  ValueNotifier<bool> get isSearchActive;

  void fetchSongs();
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
  });

  @override
  final ValueNotifier<SongBookViewState> stateNotifier =
      ValueNotifier<SongBookViewState>(SongBookViewState.initial());

  @override
  final ValueNotifier<bool> isSearchActive = ValueNotifier<bool>(false);

  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void fetchSongs() async {
    stateNotifier.value = SongBookViewState.loading();

    final result = await fetchSongsUseCase(searchQuery: _searchQuery).run();
    result.fold(
      (exception) {
        stateNotifier.value = SongBookViewState.failure(exception.message);
      },
      (fetchSongResult) {
        final songList = fetchSongResult.songs;
        if (songList.isEmpty) {
          stateNotifier.value =
              SongBookViewState.empty(searchQuery: _searchQuery);
        } else {
          stateNotifier.value =
              SongBookViewState.loaded(songList, searchQuery: _searchQuery);
        }
      },
    );
  }

  @override
  void toggleSearch() {
    isSearchActive.value = !isSearchActive.value;
    if (!isSearchActive.value) {
      _searchQuery = '';
      fetchSongs();
    }
  }

  @override
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), fetchSongs);
  }
}
