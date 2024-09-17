part of 'songbookfeature.dart';

class SongBookViewState {
  const SongBookViewState({required this.type});

  final SongBookViewStateType type;

  factory SongBookViewState.initial() =>
      const SongBookViewState(type: SongBookViewStateType.initial);
  factory SongBookViewState.loading() => Loading();
  factory SongBookViewState.loaded(List<SongItem> songList,
          {required String searchQuery}) =>
      Loaded(songList, searchQuery: searchQuery);
  factory SongBookViewState.empty({required String searchQuery}) =>
      Empty(searchQuery: searchQuery);
  factory SongBookViewState.failure(String error) => Failure(error);

  @override
  String toString() {
    return 'SongBookViewState{type: $type}';
  }
}

class Loading extends SongBookViewState {
  Loading() : super(type: SongBookViewStateType.loading);

  // fake song list for skeleton loading
  final List<SongItem> songList = List.generate(
    10,
    (index) => SongItem(
      title: 'Song $index',
      artist: 'Artist $index',
      imageURL: 'https://via.placeholder.com/150',
      alreadyPlayed: false,
    ),
  );
}

class Loaded extends SongBookViewState {
  Loaded(
    this.songList, {
    required this.searchQuery,
    super.type = SongBookViewStateType.loaded,
  }) : super();

  final String searchQuery;
  final List<SongItem> songList;
}

class Empty extends Loaded {
  Empty({required super.searchQuery})
      : super([], type: SongBookViewStateType.empty);

  LocalizedString localizedFrom(GenericLocalizations localizations) {
    final songBookLocalizations = localizations as SongBookLocalizations;
    final searchQuery = this.searchQuery;
    if (searchQuery.trim().isNotEmpty) {
      return songBookLocalizations.songNotFound(searchQuery);
    } else {
      return songBookLocalizations.emptySongBook;
    }
  }
}

class Failure extends SongBookViewState {
  final String error;
  Failure(this.error) : super(type: SongBookViewStateType.failure);
}

enum SongBookViewStateType {
  initial,
  loading,
  loaded,
  empty,
  failure,
}
