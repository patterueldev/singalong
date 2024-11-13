part of 'singalong_api_client.dart';

class APISessionManager {
  final SingalongConfiguration _configuration;
  APISessionManager({
    required SingalongConfiguration configuration,
    String? accessToken,
    String? refreshToken,
  })  : _configuration = configuration,
        _accessToken = accessToken,
        _refreshToken = refreshToken;

  String? _accessToken;
  String? _refreshToken;

  void setAccessToken(String token) => _accessToken = token;
  String getAccessToken() => _accessToken!;
  bool hasAccessToken() => _accessToken != null;
  void clearAccessToken() => _accessToken = null;

  void setRefreshToken(String? token) => _refreshToken = token;
  String? getRefreshToken() => _refreshToken;
  bool hasRefreshToken() => _refreshToken != null;
  void clearRefreshToken() => _refreshToken = null;
}
