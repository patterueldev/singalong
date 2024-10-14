part of 'singalong_api_client.dart';

class APISessionManager {
  final SingalongAPIConfiguration _configuration;
  APISessionManager({
    required SingalongAPIConfiguration configuration,
  }) : _configuration = configuration;

  String? _accessToken;
  IO.Socket? _socket;

  void setAccessToken(String token) {
    _accessToken = token;

    final base = _configuration.socketBaseUrl;
    final uri = "$base/singalong";
    debugPrint("Building socket with: $uri");
    debugPrint("Authenticating socket with token: $token");
    final option = IO.OptionBuilder()
        .setTransports(['websocket']) // for Flutter or Dart VM
        .disableAutoConnect() // disable auto-connection
        .setExtraHeaders({'Authorization': 'Bearer $token'})
        .setAuth({'token': token})
        .build();
    debugPrint("Socket option: $option");
    _socket = IO.io(
      uri,
      option,
    );
  }

  String getAccessToken() {
    return _accessToken!; // throws exception if null
  }

  IO.Socket getSocket() {
    return _socket!; // throws exception if null
  }

  bool hasAccessToken() {
    return _accessToken != null;
  }

  void clearAccessToken() {
    _accessToken = null;
  }
}
