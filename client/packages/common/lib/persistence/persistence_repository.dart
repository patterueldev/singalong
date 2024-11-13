part of '../common.dart';

abstract class PersistenceRepository {
  Future<void> saveUsername(String username);
  Future<String?> getUsername();

  Future<void> saveRoomId(String roomId);
  Future<String?> getRoomId();

  Future<void> saveAccessToken(String accessToken);
  Future<String?> getAccessToken();
  Future<void> clearAccessToken();

  Future<void> saveRefreshToken(String? refreshToken);
  Future<String?> getRefreshToken();
  Future<void> clearRefreshToken();

  Future<void> saveCustomHost(String customHost);
  Future<String?> getCustomHost();
  Future<void> clearCustomHost();

  Future<String> getDeviceId();
}
