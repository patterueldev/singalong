part of '../adminfeature.dart';

abstract class RoomsRepository {
  Future<String> newRoomID();
  Future<LoadRoomsResponse> loadRooms(LoadRoomsParameters parameters);
  Future<ConnectWithRoomResponse> connectWithRoom(Room room);
}
