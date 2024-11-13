part of '../adminfeature.dart';

abstract class RoomsRepository {
  Future<LoadRoomsResponse> loadRooms(LoadRoomsParameters parameters);
  Future<ConnectWithRoomResponse> connectWithRoom(Room room);
}
