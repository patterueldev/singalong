part of '../commonds.dart';

class ConnectRepositoryDS implements ConnectRepository {
  final SingalongAPI client;
  final SingalongSocket socket;
  final APISessionManager sessionManager;
  final PersistenceRepository persistenceRepository;

  ConnectRepositoryDS({
    required this.client,
    required this.socket,
    required this.sessionManager,
    required this.persistenceRepository,
  });

  @override
  Future<ConnectResponse> connect(ConnectParameters parameters) async {
    final result = await client.connect(parameters.toAPI());
    return result.fromAPI();
  }

  @override
  void provideAccessToken(String accessToken) {
    sessionManager.setAccessToken(accessToken);
    socket.buildSocket();
  }

  @override
  void connectSocket() {
    socket.connectSocket();
  }

  @override
  Future<bool> checkAuthentication() async {
    final accessToken = await persistenceRepository.getAccessToken();
    if (accessToken != null) {
      debugPrint('Access token found: $accessToken');
      sessionManager.setAccessToken(accessToken);
      return true;
    }
    debugPrint('No access token found');
    return false;
  }
}

extension ConnectParametersMapper on ConnectParameters {
  APIConnectParameters toAPI() {
    return APIConnectParameters(
      username: username,
      userPasscode: userPasscode,
      roomId: roomId,
      roomPasscode: roomPasscode,
      clientType: clientType.value,
    );
  }
}

extension APIConnectResponseMapper on APIConnectResponseData {
  ConnectResponse fromAPI() {
    return ConnectResponse(
      requiresUserPasscode: requiresUserPasscode,
      requiresRoomPasscode: requiresRoomPasscode,
      accessToken: accessToken,
    );
  }
}
