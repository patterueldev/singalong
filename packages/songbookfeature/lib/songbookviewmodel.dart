part of 'songbookfeature.dart';

abstract class SongBookViewModel {
  ValueNotifier<SongBookViewState> get stateNotifier;
  ValueNotifier<bool> get isSearchActive;

  void fetchSongs();
  void toggleSearch();
  void updateSearchQuery(String query);
}

class DefaultSongBookViewModel extends SongBookViewModel {
  @override
  final ValueNotifier<SongBookViewState> stateNotifier =
      ValueNotifier<SongBookViewState>(SongBookViewState.initial());

  @override
  final ValueNotifier<bool> isSearchActive = ValueNotifier<bool>(false);

  String _searchQuery = '';

  @override
  void fetchSongs() async {
    stateNotifier.value = SongBookViewState.loading();

    // Simulate fetching data
    await Future.delayed(const Duration(seconds: 2));
    final songList = [
      SongItem(
        title: 'Song 1',
        artist: 'Artist 1',
        imageURL: 'https://via.placeholder.com/150',
        alreadyPlayed: false,
      ),
      SongItem(
        title: 'Song 2',
        artist: 'Artist 2',
        imageURL: 'https://via.placeholder.com/150',
        alreadyPlayed: true,
      ),
      SongItem(
        title: 'Song 3',
        artist: 'Artist 3',
        imageURL: 'https://via.placeholder.com/150',
        alreadyPlayed: false,
      ),
    ];

    final String? searchQuery =
        _searchQuery.trim().isNotEmpty ? _searchQuery : null;
    stateNotifier.value =
        SongBookViewState.loaded([], searchQuery: searchQuery);
  }

  @override
  void toggleSearch() {
    isSearchActive.value = !isSearchActive.value;
  }

  @override
  void updateSearchQuery(String query) {
    _searchQuery = query;
    fetchSongs();
  }
}
