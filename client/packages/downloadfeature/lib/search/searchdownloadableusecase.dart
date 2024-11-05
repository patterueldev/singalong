part of '../downloadfeature.dart';

abstract class SearchDownloadableSongUseCase {
  TaskEither<GenericException, DownloadableSongsResult> call(String query);
}

class DownloadableSongsResult {
  final List<DownloadableItem> songs;
  final int? nextOffset;
  final String? nextCursor;
  final int? nextPage;

  DownloadableSongsResult(this.songs,
      {this.nextOffset, this.nextCursor, this.nextPage});

  Pagination? next() {
    if (nextOffset != null) {
      return OffsetPagination(nextOffset as int);
    } else if (nextCursor != null) {
      return CursorPagination(nextCursor as String);
    } else if (nextPage != null) {
      return PagePagination(nextPage as int);
    } else {
      return null;
    }
  }
}
