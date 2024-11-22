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
  factory SearchDownloadableViewState.failure(GenericException exception) =>
      Failure(exception);

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
      sourceUrl: 'https://example.com/song$index.mp3',
      title: 'Song $index',
      artist: 'Artist $index',
      thumbnailURL: 'https://example.com/thumbnail1.jpg',
      duration: '3:45',
      alreadyDownloaded: false,
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
    if (searchText.isEmpty) {
      return songBookLocalizations.enterSearchKeyword;
    }
    return songBookLocalizations.itemNotFound(searchText);
  }
}

class Failure extends SearchDownloadableViewState {
  final GenericException exception;
  Failure(this.exception) : super(SearchDownloadableViewStateType.failure);
}

enum SearchDownloadableViewStateType {
  initial,
  loading,
  loaded,
  notFound,
  failure,
}
