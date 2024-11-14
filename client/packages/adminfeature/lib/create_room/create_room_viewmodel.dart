part of '../adminfeature.dart';

abstract class CreateRoomViewModel extends ChangeNotifier {
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  ValueNotifier<PromptModel?> promptNotifier = ValueNotifier(null);

  String roomId = '';
  String roomName = '';
  String roomPasscode = '';

  void generateRoomID();

  void updateRoomId(String value) {
    roomId = value;
  }

  void updateRoomName(String value) {
    roomName = value;
  }

  void updateRoomPasscode(String value) {
    roomPasscode = value;
  }

  void create();
}

class DefaultCreateRoomViewModel extends CreateRoomViewModel {
  final RoomsRepository roomRepository;
  DefaultCreateRoomViewModel({
    required this.roomRepository,
  }) {
    generateRoomID();
  }

  @override
  void generateRoomID() async {
    isLoadingNotifier.value = true;

    try {
      final roomId = await roomRepository.newRoomID();
      print('roomId: $roomId');
      this.roomId = roomId;
      notifyListeners();
    } catch (e) {
      print(e);
      promptNotifier.value = PromptModel.quick(
        title: 'Error',
        message: 'Failed to load rooms: $e',
        actionText: 'OK',
      );
    }

    isLoadingNotifier.value = false;
  }

  @override
  void create() async {
    isLoadingNotifier.value = true;

    try {
      await Future.delayed(const Duration(seconds: 2));
      throw UnimplementedError();
      // await _roomRepository.create(
      //   roomId: roomId,
      //   roomName: roomName,
      //   roomPasscode: roomPasscode,
      // );
    } catch (e) {
      print(e);
    }

    isLoadingNotifier.value = false;
  }
}
