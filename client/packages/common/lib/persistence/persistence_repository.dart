part of '../common.dart';

abstract class PersistenceRepository {
  Future<void> saveUsername(String username);
  Future<String?> getUsername();

  Future<void> saveRoomId(String roomId);
  Future<String?> getRoomId();

  Future<void> saveAccessToken(String accessToken);
  Future<String?> getAccessToken();
}
