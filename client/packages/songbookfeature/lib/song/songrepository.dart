part of '../songbookfeature.dart';

class LoadSongsResult {
  final List<SongItem> songs;
  final int? nextOffset;
  final String? nextCursor;
  final int? nextPage;

  LoadSongsResult(this.songs,
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

abstract class SongRepository {
  Future<LoadSongsResult> loadSongs(LoadSongsParameters parameters);
  Future<void> reserveSong(SongItem song);
}

class LoadSongsParameters {
  final String? keyword;
  final int? limit;
  final int? nextOffset;
  final String? nextCursor;
  final int? nextPage;

  LoadSongsParameters._({
    this.keyword = null,
    this.limit = null,
    this.nextOffset = null,
    this.nextCursor = null,
    this.nextPage = null,
  });

  void validate() {
    final nonNullCount =
        [nextOffset, nextCursor, nextPage].where((it) => it != null).length;
    assert(nonNullCount <= 1,
        "Only one of offset, cursor, or page should be non-null.");
  }

  @override
  String toString() {
    return 'LoadSongsParameters{keyword: $keyword, limit: $limit, nextOffset: $nextOffset, nextCursor: $nextCursor, nextPage: $nextPage}';
  }

  factory LoadSongsParameters.next({
    String? keyword,
    int? limit,
    Pagination? nextPage,
  }) {
    if (nextPage is OffsetPagination) {
      return LoadSongsParameters._(
        keyword: keyword,
        limit: limit,
        nextOffset: nextPage.offset,
      );
    } else if (nextPage is CursorPagination) {
      return LoadSongsParameters._(
        keyword: keyword,
        limit: limit,
        nextCursor: nextPage.cursor,
      );
    } else if (nextPage is PagePagination) {
      return LoadSongsParameters._(
        keyword: keyword,
        limit: limit,
        nextPage: nextPage.page,
      );
    } else {
      if (nextPage != null) {
        throw ArgumentError("Invalid pagination type");
      } else {
        return LoadSongsParameters._(
          keyword: keyword,
          limit: limit,
        );
      }
    }
  }
}

/*

    fun nextPage(): Pagination? {
        return if (offset != null) {
            Pagination.OffsetPagination(offset)
        } else if (cursor != null) {
            Pagination.CursorPagination(cursor)
        } else if (page != null) {
            Pagination.PagePagination(page)
        } else {
            null
        }
    }

sealed class Pagination {
    data class OffsetPagination(val nextOffset: Int) : Pagination()

    data class CursorPagination(val nextCursor: String) : Pagination()

    data class PagePagination(val pageNumber: Int) : Pagination() // Limit can be set externally

    object NoMorePages : Pagination()
}

 */
