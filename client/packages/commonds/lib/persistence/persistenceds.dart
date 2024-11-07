part of '../commonds.dart';

class PersistenceRepositoryDS implements PersistenceRepository {
  final String encryptionKey;

  PersistenceRepositoryDS({required this.encryptionKey});

  final roomKey = 'room';
  final usernameKey = 'username';
  final accessTokenKey = 'accessToken';

  EncryptedSharedPreferences? sharedPref;

  Future<void> configureSharedPref() async {
    if (sharedPref == null) {
      await EncryptedSharedPreferences.initialize(encryptionKey);
      sharedPref = EncryptedSharedPreferences.getInstance();
    }
  }

  @override
  Future<String?> getRoomId() async {
    await configureSharedPref();
    final roomId = sharedPref!.getString(roomKey);
    debugPrint('Retrieved room id: $roomId');
    return roomId;
  }

  @override
  Future<String?> getUsername() async {
    await configureSharedPref();
    final username = sharedPref!.getString(usernameKey);
    debugPrint('Retrieved username: $username');
    return username;
  }

  @override
  Future<String?> getAccessToken() async {
    await configureSharedPref();
    final accessToken = sharedPref!.getString(accessTokenKey);
    debugPrint('Retrieved access token: $accessToken');
    return accessToken;
  }

  @override
  Future<void> saveRoomId(String roomId) async {
    await configureSharedPref();
    debugPrint('Saving room id: $roomId');
    sharedPref!.setString(roomKey, roomId);
  }

  @override
  Future<void> saveUsername(String username) async {
    await configureSharedPref();
    debugPrint('Saving username: $username');
    sharedPref!.setString(usernameKey, username);
  }

  @override
  Future<void> saveAccessToken(String accessToken) async {
    await configureSharedPref();
    debugPrint('Saving access token: $accessToken');
    sharedPref!.setString(accessTokenKey, accessToken);
  }
}
