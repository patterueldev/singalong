part of '../downloadfeature.dart';

class SearchDownloadableViewState {
  const SearchDownloadableViewState(this.type);

  final SearchDownloadableViewStateType type;

  factory SearchDownloadableViewState.initial() =>
      const SearchDownloadableViewState(
          SearchDownloadableViewStateType.initial);
  factory SearchDownloadableViewState.loading() => Loading();
  factory SearchDownloadableViewState.loaded(List<DownloadableItem> songList) =>
      Loaded(songList);
  factory SearchDownloadableViewState.notFound({required String searchText}) =>
      NotFound(searchText);
  factory SearchDownloadableViewState.failure(String error) => Failure(error);

  @override
  String toString() {
    return 'SongBookViewState{type: $type}';
  }
}

class Loading extends SearchDownloadableViewState {
  Loading() : super(SearchDownloadableViewStateType.loading);

  // fake song list for skeleton loading
  final List<DownloadableItem> downloadableList = List.generate(
    10,
    (index) => DownloadableItem(
      title: 'Song $index',
      artist: 'Artist $index',
      thumbnailURL: 'https://example.com/thumbnail1.jpg',
      duration: '3:45',
    ),
  );
}

class Loaded extends SearchDownloadableViewState {
  Loaded(this.downloadableList) : super(SearchDownloadableViewStateType.loaded);
  final List<DownloadableItem> downloadableList;
}

class NotFound extends SearchDownloadableViewState {
  NotFound(this.searchText) : super(SearchDownloadableViewStateType.notFound);

  final String searchText;

  LocalizedString localizedFrom(GenericLocalizations localizations) {
    final songBookLocalizations = localizations as DownloadLocalizations;
    return songBookLocalizations.itemNotFound(searchText);
  }
}

class Failure extends SearchDownloadableViewState {
  final String error;
  Failure(this.error) : super(SearchDownloadableViewStateType.failure);
}

enum SearchDownloadableViewStateType {
  initial,
  loading,
  loaded,
  notFound,
  failure,
}
