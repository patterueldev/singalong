part of '../adminfeature.dart';

class LoadRoomsUseCase
    extends MacroServiceUseCase<LoadRoomsParameters, LoadRoomsResponse> {
  final RoomsRepository roomsRepository;

  LoadRoomsUseCase({
    required this.roomsRepository,
  });

  @override
  Future<LoadRoomsResponse> tryTask(LoadRoomsParameters parameters) async {
    return await roomsRepository.loadRooms(parameters);
  }
}
