part of '../songbookfeature.dart';

class SongBookViewState {
  const SongBookViewState(this.type);

  final SongBookViewStateType type;

  factory SongBookViewState.initial() =>
      const SongBookViewState(SongBookViewStateType.initial);
  factory SongBookViewState.loading() => Loading();
  factory SongBookViewState.loaded(List<SongItem> songList) => Loaded(songList);
  factory SongBookViewState.notFound({required String searchText}) =>
      NotFound(searchText);
  factory SongBookViewState.urlDetected(String url) => URLDetected(url);
  factory SongBookViewState.failure(GenericException exception) =>
      Failure(exception);

  @override
  String toString() {
    return 'SongBookViewState{type: $type}';
  }
}

class Loading extends SongBookViewState {
  Loading() : super(SongBookViewStateType.loading);

  // fake song list for skeleton loading
  final List<SongItem> songList = List.generate(
    10,
    (index) => SongItem(
      id: index.toString(),
      title: 'Song $index',
      artist: 'Artist $index',
      thumbnailURL: 'https://via.placeholder.com/150',
      alreadyPlayed: false,
    ),
  );
}

class Loaded extends SongBookViewState {
  Loaded(this.songList) : super(SongBookViewStateType.loaded);
  final List<SongItem> songList;
}

class NotFound extends SongBookViewState {
  NotFound(this.searchText) : super(SongBookViewStateType.notFound);

  final String searchText;

  LocalizedString localizedFrom(GenericLocalizations localizations) {
    final songBookLocalizations = localizations as SongBookLocalizations;
    final searchQuery = searchText;
    if (searchQuery.trim().isNotEmpty) {
      return songBookLocalizations.songNotFound(searchQuery);
    } else {
      return songBookLocalizations.emptySongBook;
    }
  }
}

class URLDetected extends SongBookViewState {
  URLDetected(this.url) : super(SongBookViewStateType.urlDetected);
  final String url;

  LocalizedString localizedFrom(GenericLocalizations localizations) {
    final songBookLocalizations = localizations as SongBookLocalizations;
    return songBookLocalizations.urlDetected(url);
  }
}

class Failure extends SongBookViewState {
  final GenericException exception;
  Failure(this.exception) : super(SongBookViewStateType.failure);
}

enum SongBookViewStateType {
  initial,
  loading,
  loaded,
  notFound,
  urlDetected,
  failure,
}
