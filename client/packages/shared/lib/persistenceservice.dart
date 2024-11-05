part of 'shared.dart';

abstract class PersistenceService {
  Future<void> saveUsername(String username);
  Future<String?> getUsername();

  Future<void> saveRoomId(String roomId);
  Future<String?> getRoomId();
}
