part of '../connectfeature.dart';

abstract class ConnectRepository {
  Future<ConnectResponse> connect(ConnectParameters parameters);
  void provideAccessToken(String accessToken);
}

class ConnectParameters {
  final String username;
  final String? userPasscode;
  final String roomId;
  final String? roomPasscode;
  final String clientType;

  ConnectParameters({
    required this.username,
    this.userPasscode,
    required this.roomId,
    this.roomPasscode,
    required this.clientType,
  });
}

class ConnectResponse {
  final bool? requiresUserPasscode;
  final bool? requiresRoomPasscode;
  final String? accessToken;

  ConnectResponse({
    this.requiresUserPasscode,
    this.requiresRoomPasscode,
    this.accessToken,
  });
}
