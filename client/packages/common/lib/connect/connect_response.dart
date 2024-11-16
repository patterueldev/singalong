part of '../common.dart';

class ConnectResponse {
  final bool? requiresUserPasscode;
  final bool? requiresRoomPasscode;
  final String? accessToken;
  final String? refreshToken;

  ConnectResponse({
    this.requiresUserPasscode,
    this.requiresRoomPasscode,
    this.accessToken,
    this.refreshToken,
  });
}
