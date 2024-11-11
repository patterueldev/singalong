part of '../adminfeature.dart';

abstract class RoomsRepository {
  Future<LoadRoomsResponse> loadRooms(LoadRoomsParameters parameters);
}

class LoadRoomsParameters {
  final String? keyword;
  final int? limit;
  final int? nextOffset;
  final String? nextCursor;
  final int? nextPage;

  LoadRoomsParameters._({
    this.keyword,
    this.limit,
    this.nextOffset,
    this.nextCursor,
    this.nextPage,
  });

  void validate() {
    final nonNullCount =
        [nextOffset, nextCursor, nextPage].where((it) => it != null).length;
    assert(nonNullCount <= 1,
        "Only one of offset, cursor, or page should be non-null.");
  }

  @override
  String toString() {
    return 'LoadRoomsParameters{limit: $limit, nextOffset: $nextOffset, nextCursor: $nextCursor, nextPage: $nextPage}';
  }

  factory LoadRoomsParameters.next({
    String? keyword,
    int? limit,
    Pagination? nextPage,
  }) {
    if (nextPage is OffsetPagination) {
      return LoadRoomsParameters._(
        keyword: keyword,
        limit: limit,
        nextOffset: nextPage.offset,
      );
    } else if (nextPage is CursorPagination) {
      return LoadRoomsParameters._(
        keyword: keyword,
        limit: limit,
        nextCursor: nextPage.cursor,
      );
    } else if (nextPage is PagePagination) {
      return LoadRoomsParameters._(
        keyword: keyword,
        limit: limit,
        nextPage: nextPage.page,
      );
    } else {
      if (nextPage != null) {
        throw ArgumentError("Invalid pagination type");
      } else {
        return LoadRoomsParameters._(
          keyword: keyword,
          limit: limit,
        );
      }
    }
  }
}

class LoadRoomsResponse {
  final List<Room> rooms;
  final int? nextOffset;
  final String? nextCursor;
  final int? nextPage;

  LoadRoomsResponse({
    required this.rooms,
    this.nextOffset,
    this.nextCursor,
    this.nextPage,
  });
}
