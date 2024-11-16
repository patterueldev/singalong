part of '../commonds.dart';

class ConnectRepositoryDS implements ConnectRepository {
  final SingalongAPI api;
  final SingalongSocket socket;
  final APISessionManager sessionManager;
  final PersistenceRepository persistenceRepository;

  ConnectRepositoryDS({
    required this.api,
    required this.socket,
    required this.sessionManager,
    required this.persistenceRepository,
  });

  @override
  Future<ConnectResponse> connect(ConnectParameters parameters) async {
    String deviceId = await persistenceRepository.getDeviceId();
    final result = await api.connect(
      parameters.toAPI(deviceId: deviceId),
    );
    return result.fromAPI();
  }

  @override
  void provideAccessToken(String accessToken) {
    sessionManager.setAccessToken(accessToken);
  }

  @override
  Future<void> connectRoomSocket(String roomId) async {
    await socket.connectRoomSocket(roomId);
  }

  @override
  Future<bool> checkAuthentication() async {
    final accessToken = await persistenceRepository.getAccessToken();
    if (accessToken == null) {
      debugPrint('No access token found');
      return false;
    }

    debugPrint('Access token found: $accessToken');
    sessionManager.setAccessToken(accessToken);

    try {
      final result = await api.check();
      debugPrint('Check result: $result');
      return true;
    } catch (e) {
      debugPrint('Check error: $e');
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    socket.disconnectRoomSocket();
    sessionManager.clearAccessToken();
    await persistenceRepository.clearAccessToken();
  }
}

extension ConnectParametersMapper on ConnectParameters {
  APIConnectParameters toAPI({required String deviceId}) {
    return APIConnectParameters(
      username: username,
      userPasscode: userPasscode,
      roomId: roomId,
      roomPasscode: roomPasscode,
      clientType: clientType.value,
      deviceId: deviceId,
    );
  }
}

extension APIConnectResponseMapper on APIConnectResponseData {
  ConnectResponse fromAPI() {
    return ConnectResponse(
      requiresUserPasscode: requiresUserPasscode,
      requiresRoomPasscode: requiresRoomPasscode,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
