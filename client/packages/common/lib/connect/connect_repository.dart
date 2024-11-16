part of '../common.dart';

abstract class ConnectRepository {
  Future<ConnectResponse> connect(ConnectParameters parameters);
  void provideAccessToken(String accessToken);
  Future<void> connectRoomSocket(String roomId);
  Future<bool> checkAuthentication();
  Future<void> disconnect();
}
