part of '../songbookfeature.dart';

abstract class SongBookViewModel extends ChangeNotifier {
  ValueNotifier<SongBookViewState> get stateNotifier;
  ValueNotifier<bool> get isSearchActive;
  ValueNotifier<bool> get isLoadingNotifier; // for the HUD overlay
  ValueNotifier<String?> get toastMessageNotifier;
  ValueNotifier<bool> reservedNotifier = ValueNotifier(false);

  void fetchSongs(bool loadsNext);
  void toggleSearch();
  void updateSearchQuery(String query);
  void reserveSong(SongbookItem song);
}

class DefaultSongBookViewModel extends SongBookViewModel {
  final FetchSongsUseCase fetchSongsUseCase;
  final ReserveSongUseCase reserveSongUseCase;
  final SongBookLocalizations localizations;
  final String? roomId;

  DefaultSongBookViewModel({
    required this.fetchSongsUseCase,
    required this.reserveSongUseCase,
    required this.localizations,
    this.roomId,
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
  void fetchSongs(
    bool loadsNext, {
    bool isFromTimer = false,
  }) async {
    final keyword = _searchQuery;
    debugPrint('Fetching songs with keyword: $keyword');

    stateNotifier.value = SongBookViewState.loading();
    final parameters = LoadSongsParameters.next(
      keyword: _searchQuery,
      limit: 100,
      nextPage: loadsNext ? nextPage : null,
      roomId: roomId,
    );
    final result = await fetchSongsUseCase(parameters).run();
    result.fold(
      (exception) {
        stateNotifier.value = SongBookViewState.failure(exception);
      },
      (fetchSongResult) {
        final songList = fetchSongResult.songs;
        nextPage = fetchSongResult.next();

        if (songList.isNotEmpty) {
          final state = stateNotifier.value;
          if (state is Loaded) {
            final currentSongs = state.songList;
            songList.insertAll(0, currentSongs);
          }
          stateNotifier.value = SongBookViewState.loaded(songList);
          return;
        }

        // song is empty
        try {
          if (keyword == null) {
            throw Exception('Keyword is null');
          }
          final url = Uri.parse(keyword);
          if (!url.isAbsolute) {
            throw Exception('Keyword is not a URL');
          }
          stateNotifier.value = SongBookViewState.urlDetected(url.toString());
        } catch (e) {
          debugPrint(e.toString());
          stateNotifier.value =
              SongBookViewState.notFound(searchText: _searchQuery ?? '');
        }
      },
    );
  }

  @override
  void reserveSong(SongbookItem song) async {
    isLoadingNotifier.value = true;
    final result = await reserveSongUseCase(song).run();
    result.fold(
      (exception) {
        isLoadingNotifier.value = false;
        stateNotifier.value = SongBookViewState.failure(exception);
      },
      (_) {
        isLoadingNotifier.value = false;
        // maybe show a toast
        toastMessageNotifier.value = 'Song reserved';
        // refresh
        fetchSongs(false);

        reservedNotifier.value = true;
      },
    );
  }

  @override
  void toggleSearch() {
    isSearchActive.value = !isSearchActive.value;
    if (!isSearchActive.value) {
      _searchQuery = null;
      fetchSongs(false, isFromTimer: false);
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
    _searchDebounce =
        Timer(debounceTime, () => fetchSongs(false, isFromTimer: true));
  }
}
