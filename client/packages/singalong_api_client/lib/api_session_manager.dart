part of 'singalong_api_client.dart';

class APISessionManager {
  final SingalongConfiguration _configuration;
  APISessionManager({
    required SingalongConfiguration configuration,
  }) : _configuration = configuration;

  String? _accessToken;

  void setAccessToken(String token) => {
        if (_accessToken != null) throw Exception('Access token already set'),
        _accessToken = token
      };
  String getAccessToken() => _accessToken!;
  bool hasAccessToken() => _accessToken != null;
  void clearAccessToken() => _accessToken = null;
}
