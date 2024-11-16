part of '../commonds.dart';

class PersistenceRepositoryDS implements PersistenceRepository {
  final String encryptionKey;

  PersistenceRepositoryDS({required this.encryptionKey});

  final roomKey = 'room';
  final usernameKey = 'username';
  final accessTokenKey = 'accessToken';
  final refreshTokenKey = 'refreshToken';
  final deviceIdKey = 'deviceId';
  final uniqueNameKey = 'uniqueName';
  final customHostKey = 'customHost';

  EncryptedSharedPreferences? sharedPref;
  final uuid = Uuid();

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
  Future<String?> getRefreshToken() async {
    await configureSharedPref();
    final refreshToken = sharedPref!.getString(refreshTokenKey);
    debugPrint('Retrieved refresh token: $refreshToken');
    return refreshToken;
  }

  @override
  Future<String?> getCustomHost() async {
    await configureSharedPref();
    final customHost = sharedPref!.getString(customHostKey);
    debugPrint('Retrieved custom host: $customHost');
    return customHost;
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

  @override
  Future<void> saveRefreshToken(String? refreshToken) async {
    await configureSharedPref();
    debugPrint('Saving refresh token: $refreshToken');
    sharedPref!.setString(refreshTokenKey, refreshToken!);
  }

  @override
  Future<void> saveCustomHost(String customHost) async {
    await configureSharedPref();
    debugPrint('Saving custom host: $customHost');
    sharedPref!.setString(customHostKey, customHost);
  }

  @override
  Future<void> clearAccessToken() async {
    await configureSharedPref();
    debugPrint('Clearing access token');
    sharedPref!.remove(accessTokenKey);
  }

  @override
  Future<void> clearCustomHost() async {
    await configureSharedPref();
    debugPrint('Clearing custom host');
    sharedPref!.remove(customHostKey);
  }

  @override
  Future<void> clearRefreshToken() async {
    await configureSharedPref();
    debugPrint('Clearing refresh token');
    sharedPref!.remove(refreshTokenKey);
  }

  @override
  Future<String> getDeviceId() async {
    await configureSharedPref();
    var deviceId = sharedPref!.getString(deviceIdKey);
    if (deviceId == null) {
      deviceId = uuid.v4();
      sharedPref!.setString(deviceIdKey, deviceId);
    }
    return deviceId;
  }

  @override
  Future<String> getUniqueName() async {
    await configureSharedPref();
    var uniqueName = sharedPref!.getString(uniqueNameKey);
    if (uniqueName?.contains(' ') == true) {
      uniqueName = null;
    }
    if (uniqueName == null) {
      final faker = Faker.instance;
      final genre = faker.music.genre();
      final animal = faker.animal.animal();
      uniqueName = '$genre$animal'.replaceAll(' ', '');
      sharedPref!.setString(uniqueNameKey, uniqueName);
    }
    debugPrint('Unique name: $uniqueName');
    return uniqueName;
  }
}
