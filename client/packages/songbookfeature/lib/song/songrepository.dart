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
  final String? roomId;

  LoadSongsParameters._({
    this.keyword,
    this.limit,
    this.nextOffset,
    this.nextCursor,
    this.nextPage,
    this.roomId,
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
    String? roomId,
  }) {
    if (nextPage is OffsetPagination) {
      return LoadSongsParameters._(
        keyword: keyword,
        limit: limit,
        nextOffset: nextPage.offset,
        roomId: roomId,
      );
    } else if (nextPage is CursorPagination) {
      return LoadSongsParameters._(
        keyword: keyword,
        limit: limit,
        nextCursor: nextPage.cursor,
        roomId: roomId,
      );
    } else if (nextPage is PagePagination) {
      return LoadSongsParameters._(
        keyword: keyword,
        limit: limit,
        nextPage: nextPage.page,
        roomId: roomId,
      );
    } else {
      if (nextPage != null) {
        throw ArgumentError("Invalid pagination type");
      } else {
        return LoadSongsParameters._(
          keyword: keyword,
          limit: limit,
          roomId: roomId,
        );
      }
    }
  }
}
