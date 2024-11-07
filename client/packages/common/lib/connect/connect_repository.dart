part of '../common.dart';

abstract class ConnectRepository {
  Future<ConnectResponse> connect(ConnectParameters parameters);
  void provideAccessToken(String accessToken);
  void connectSocket();
  Future<bool> checkAuthentication();
}
