part of 'songbookfeature.dart';

class SongBookViewState {
  const SongBookViewState(this.type);

  final SongBookViewStateType type;

  factory SongBookViewState.initial() =>
      const SongBookViewState(SongBookViewStateType.initial);
  factory SongBookViewState.loading() => Loading();
  factory SongBookViewState.loaded(List<SongItem> songList,
          {required String? searchQuery}) =>
      Loaded(songList, searchQuery: searchQuery);
  factory SongBookViewState.failure(String error) => Failure(error);
}

class Loading extends SongBookViewState {
  Loading() : super(SongBookViewStateType.loading);

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
  Loaded(this.songList, {required this.searchQuery})
      : super(SongBookViewStateType.loaded);

  final String? searchQuery;
  final List<SongItem> songList;
}

class Failure extends SongBookViewState {
  final String error;
  Failure(this.error) : super(SongBookViewStateType.failure);
}

enum SongBookViewStateType {
  initial,
  loading,
  loaded,
  failure,
}
