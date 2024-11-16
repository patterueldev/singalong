part of '../adminfeature.dart';

abstract class RoomsRepository {
  Future<String> newRoomID();
  Future<LoadRoomsResponse> loadRooms(LoadRoomsParameters parameters);
  Future<ConnectWithRoomResponse> connectWithRoom(Room room);
  Future<void> createRoom(CreateRoomParameters parameters);
}

class CreateRoomParameters {
  final String roomId;
  final String roomName;
  final String roomPasscode;

  CreateRoomParameters({
    required this.roomId,
    required this.roomName,
    this.roomPasscode = '',
  });

  void validate() {
    if (roomId.isEmpty) {
      throw 'Room ID is required';
    }
    if (roomName.isEmpty) {
      throw 'Room Name is required';
    }
  }
}
