import 'package:encrypt_shared_preferences/provider.dart';
import 'package:shared/shared.dart';

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
    return sharedPref!.getString(roomKey);
  }

  @override
  Future<String?> getUsername() async {
    await configureSharedPref();
    return sharedPref!.getString(usernameKey);
  }

  @override
  Future<void> saveRoomId(String roomId) async {
    await configureSharedPref();
    sharedPref!.setString(roomKey, roomId);
  }

  @override
  Future<void> saveUsername(String username) async {
    await configureSharedPref();
    sharedPref!.setString(usernameKey, username);
  }
}
