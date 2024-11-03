part of 'connectfeatureds.dart';

class ConnectRepositoryDS implements ConnectRepository {
  final SingalongAPIClient client;
  final APISessionManager sessionManager;
  final PersistenceService persistenceService;

  ConnectRepositoryDS({
    required this.client,
    required this.sessionManager,
    required this.persistenceService,
  });

  @override
  Future<ConnectResponse> connect(ConnectParameters parameters) async {
    final result = await client.connect(parameters.toAPI());
    return result.fromAPI();
  }

  @override
  void provideAccessToken(String accessToken) {
    sessionManager.setAccessToken(accessToken);
  }

  @override
  void saveSession(String username, String roomId) {
    persistenceService.saveUsername(username);
    persistenceService.saveRoomId(roomId);
  }
}

extension ConnectParametersMapper on ConnectParameters {
  APIConnectParameters toAPI() {
    return APIConnectParameters(
      username: username,
      roomId: roomId,
      clientType: clientType,
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
