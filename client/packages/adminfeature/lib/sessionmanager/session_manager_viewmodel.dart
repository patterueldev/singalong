part of '../adminfeature.dart';

abstract class SessionManagerViewModel extends ChangeNotifier {
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  ValueNotifier<List<Room>> roomsNotifier = ValueNotifier([]);
  ValueNotifier<bool> isDisconnectedNotifier = ValueNotifier(false);

  void load();
  void createRoom();
  void disconnect();
}

class DefaultSessionManagerViewModel extends SessionManagerViewModel {
  final RoomsRepository roomsRepository;
  final ConnectRepository connectRepository;
  final PersistenceRepository persistenceRepository;

  DefaultSessionManagerViewModel({
    required this.roomsRepository,
    required this.connectRepository,
    required this.persistenceRepository,
  }) {
    load();
  }
  late final LoadRoomsUseCase loadRoomsUseCase =
      LoadRoomsUseCase(roomsRepository: roomsRepository);

  @override
  void load() async {
    isLoadingNotifier.value = true;

    final parameters = LoadRoomsParameters.next();
    final result = await loadRoomsUseCase(parameters);
    result.fold(
      (failure) {
        // Handle failure
      },
      (response) {
        roomsNotifier.value = response.rooms;
        isLoadingNotifier.value = false;
      },
    );
    // await Future.delayed(Duration(seconds: 1));
    // final rooms = [
    //   Room(id: '1', name: 'Room 1', isSecured: true, isActive: true),
    //   Room(
    //       id: '2',
    //       name: 'Room 2',
    //       isSecured: false,
    //       isActive: false,
    //       lastActive: DateTime.now().subtract(Duration(days: 1))),
    //   // Add more rooms as needed
    // ];
    // roomsNotifier.value = rooms;
    // isLoadingNotifier.value = false;
  }

  @override
  void createRoom() {}

  @override
  void disconnect() async {
    await connectRepository.disconnect();
    isDisconnectedNotifier.value = true;
  }
}

class Room {
  final String id;
  final String name;
  final bool isSecured;
  final bool isActive;
  final DateTime? lastActive;

  Room({
    required this.id,
    required this.name,
    required this.isSecured,
    required this.isActive,
    this.lastActive,
  });
}
