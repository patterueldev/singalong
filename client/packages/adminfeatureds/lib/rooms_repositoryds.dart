part of 'adminfeatureds.dart';

class RoomsRepositoryDS implements RoomsRepository {
  final SingalongAPI api;

  RoomsRepositoryDS({
    required this.api,
  });

  @override
  Future<LoadRoomsResponse> loadRooms(LoadRoomsParameters parameters) async {
    try {
      debugPrint(
          'RoomsRepositoryDS: Fetching rooms with parameters: $parameters');
      final result = await api.loadRooms(
        APILoadRoomListParameters(
          keyword: parameters.keyword,
          limit: parameters.limit,
          nextOffset: parameters.nextOffset,
          nextCursor: parameters.nextCursor,
          nextPage: parameters.nextPage,
        ),
      );
      final apiRooms = result.items;
      final rooms = apiRooms
          .map((apiRoom) => Room(
                id: apiRoom.id,
                name: apiRoom.name,
                isSecured: apiRoom.isSecured,
                isActive: apiRoom.isActive,
                lastActive: apiRoom.lastActive,
              ))
          .toList();
      return LoadRoomsResponse(
        rooms: rooms,
        nextOffset: result.nextOffset,
        nextCursor: result.nextCursor,
        nextPage: result.nextPage,
      );
    } catch (e) {
      debugPrint("Error: $e");
      rethrow;
    }
  }
}
