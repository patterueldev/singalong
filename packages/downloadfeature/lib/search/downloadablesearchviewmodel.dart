part of '../downloadfeature.dart';

abstract class DownloadableSearchViewModel extends ChangeNotifier {
  ValueNotifier<DownloadSearchFieldStatus> get searchFieldStatusNotifier;

  void updateSearchQuery(text);
  void toggleSearch();
}

enum DownloadSearchFieldStatus {
  idle,
  searching;

  bool isSearching() => this == searching;
}

class DefaultDownloadableSearchViewModel extends DownloadableSearchViewModel {
  @override
  ValueNotifier<DownloadSearchFieldStatus> searchFieldStatusNotifier =
      ValueNotifier(DownloadSearchFieldStatus.idle);

  @override
  void updateSearchQuery(text) {
    // Implement your search query update logic here
  }

  @override
  void toggleSearch() {
    if (searchFieldStatusNotifier.value.isSearching()) {
      searchFieldStatusNotifier.value = DownloadSearchFieldStatus.idle;
    } else {
      searchFieldStatusNotifier.value = DownloadSearchFieldStatus.searching;
    }
    notifyListeners();
  }
}
