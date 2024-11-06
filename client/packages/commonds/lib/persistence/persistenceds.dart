part of '../commonds.dart';

class PersistenceServiceImpl implements PersistenceService {
  final roomKey = 'room';
  final usernameKey = 'username';

  EncryptedSharedPreferences? sharedPref;

  Future<void> configureSharedPref() async {
    if (sharedPref == null) {
      const encryptionKey = '1234567890123456';
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
}
