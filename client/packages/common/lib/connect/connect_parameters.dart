part of '../common.dart';

class ConnectParameters {
  final String username;
  final String? userPasscode;
  final String roomId;
  final String? roomPasscode;
  final ClientType clientType;

  ConnectParameters({
    required this.username,
    this.userPasscode,
    required this.roomId,
    this.roomPasscode,
    required this.clientType,
  });

  factory ConnectParameters.admin({
    required String username,
    required String userPasscode,
  }) =>
      ConnectParameters(
        username: username,
        userPasscode: userPasscode,
        roomId: 'admin',
        roomPasscode: 'admin',
        clientType: ClientType.ADMIN,
      );
}

enum ClientType {
  CONTROLLER,
  PLAYER,
  ADMIN;

  String get value {
    switch (this) {
      case ClientType.CONTROLLER:
        return 'CONTROLLER';
      case ClientType.PLAYER:
        return 'PLAYER';
      case ClientType.ADMIN:
        return 'ADMIN';
    }
  }
}
