part of '../adminfeature.dart';

class ConnectWithRoomResponse {
  final String accessToken;
  final String refreshToken;

  ConnectWithRoomResponse({
    required this.accessToken,
    required this.refreshToken,
  });
}
