part of '../adminfeature.dart';

abstract class SessionManagerViewModel extends ChangeNotifier {
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  ValueNotifier<List<Room>> roomsNotifier = ValueNotifier([]);
  ValueNotifier<bool> isDisconnectedNotifier = ValueNotifier(false);
  ValueNotifier<Room?> roomSelectionNotifier = ValueNotifier(null);

  void load();
  void createRoom();
  void selectRoom(Room room);
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
  void selectRoom(Room room) async {
    isLoadingNotifier.value = true;
    try {
      final response = await roomsRepository.connectWithRoom(room);
      debugPrint("Response: $response");
      final accessToken = response.accessToken;
      final refreshToken = response.refreshToken;
      debugPrint("Access token: $accessToken");
      debugPrint("Refresh token: $refreshToken");
      await persistenceRepository.saveAccessToken(accessToken);
      await persistenceRepository.saveRefreshToken(refreshToken);
      connectRepository.provideAccessToken(accessToken);
      connectRepository.connectSocket();
      roomSelectionNotifier.value = room;
    } catch (e) {
      debugPrint("Error while selecting room: $e");
    }
    isLoadingNotifier.value = false;
  }

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
