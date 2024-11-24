part of '../commonds.dart';

class PersistenceRepositoryDS extends PersistenceRepository {
  final String encryptionKey;

  PersistenceRepositoryDS({required this.encryptionKey});

  // with these many keys, I think it's better to use an enum and object
  final roomKey = 'room';
  final usernameKey = 'username';
  final accessTokenKey = 'accessToken';
  final refreshTokenKey = 'refreshToken';
  final deviceIdKey = 'deviceId';
  final uniqueNameKey = 'uniqueName';
  final customHostKey = 'customHost';
  final customProtocolKey = 'customProtocol';
  final customApiPortKey = 'customApiPort';

  EncryptedSharedPreferences? sharedPref;
  final uuid = Uuid();

  Future<void> configureSharedPref() async {
    if (sharedPref == null) {
      await EncryptedSharedPreferences.initialize(encryptionKey);
      sharedPref = EncryptedSharedPreferences.getInstance();
    }
  }

  @override
  Future<void> saveString(PersistenceKey key, String value) async {
    await configureSharedPref();
    debugPrint('Saving $key: $value');
    sharedPref!.setString(key.value, value);
  }

  @override
  Future<String?> getString(PersistenceKey key) async {
    await configureSharedPref();
    final value = sharedPref!.getString(key.value);
    debugPrint('Retrieved $key: $value');
    return value;
  }

  @override
  Future<void> saveInt(PersistenceKey key, int value) async {
    await configureSharedPref();
    debugPrint('Saving $key: $value');
    sharedPref!.setInt(key.value, value);
  }

  @override
  Future<int?> getInt(PersistenceKey key) async {
    await configureSharedPref();
    final value = sharedPref!.getInt(key.value);
    debugPrint('Retrieved $key: $value');
    return value;
  }

  @override
  Future<void> clear(PersistenceKey key) async {
    await configureSharedPref();
    debugPrint('Clearing $key');
    sharedPref!.remove(key.value);
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
