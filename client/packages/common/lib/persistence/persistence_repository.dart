part of '../common.dart';

abstract class PersistenceRepository {
  Future<void> saveString(PersistenceKey key, String value);
  Future<String?> getString(PersistenceKey key);

  Future<void> saveInt(PersistenceKey key, int value);
  Future<int?> getInt(PersistenceKey key);

  Future<void> clear(PersistenceKey key);

  // TODO: Delete all of these
  Future<void> saveUsername(String username) =>
      saveString(PersistenceKey.username, username);
  Future<String?> getUsername() => getString(PersistenceKey.username);

  Future<void> saveRoomId(String roomId) =>
      saveString(PersistenceKey.room, roomId);
  Future<String?> getRoomId() => getString(PersistenceKey.room);

  Future<void> saveAccessToken(String accessToken) =>
      saveString(PersistenceKey.accessToken, accessToken);
  Future<String?> getAccessToken() => getString(PersistenceKey.accessToken);
  Future<void> clearAccessToken() => clear(PersistenceKey.accessToken);

  Future<void> saveRefreshToken(String? refreshToken) =>
      saveString(PersistenceKey.refreshToken, refreshToken ?? "");
  Future<String?> getRefreshToken() => getString(PersistenceKey.refreshToken);
  Future<void> clearRefreshToken() => clear(PersistenceKey.refreshToken);

  Future<String> getDeviceId();
  Future<String> getUniqueName();
}

enum PersistenceKey {
  room,
  username,
  accessToken, // "accessToken"
  refreshToken, // "refreshToken"
  deviceId,
  uniqueName,
  // API
  customApiHost,
  customApiProtocol,
  customApiPort,

  // Socket
  customSocketHost,
  customSocketProtocol,
  customSocketPort,

  // Storage
  customStorageHost,
  customStorageProtocol,
  customStoragePort,
  ;

  String get value {
    switch (this) {
      case PersistenceKey.room:
        return "room";
      case PersistenceKey.username:
        return "username";
      case PersistenceKey.accessToken:
        return "accessToken";
      case PersistenceKey.refreshToken:
        return "refreshToken";
      case PersistenceKey.deviceId:
        return "deviceId";
      case PersistenceKey.uniqueName:
        return "uniqueName";
      case PersistenceKey.customApiHost:
        return "customApiHost";
      case PersistenceKey.customApiProtocol:
        return "customApiProtocol";
      case PersistenceKey.customApiPort:
        return "customApiPort";
      case PersistenceKey.customSocketHost:
        return "customSocketHost";
      case PersistenceKey.customSocketProtocol:
        return "customSocketProtocol";
      case PersistenceKey.customSocketPort:
        return "customSocketPort";
      case PersistenceKey.customStorageHost:
        return "customStorageHost";
      case PersistenceKey.customStorageProtocol:
        return "customStorageProtocol";
      case PersistenceKey.customStoragePort:
        return "customStoragePort";
    }
  }

  @override
  String toString() {
    return value;
  }
}
