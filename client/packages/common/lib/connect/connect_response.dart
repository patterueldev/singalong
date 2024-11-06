part of '../common.dart';

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
