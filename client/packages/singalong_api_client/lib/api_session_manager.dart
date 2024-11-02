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
    final option = IO.OptionBuilder()
        .setTransports(['websocket']) // for Flutter or Dart VM
        .disableAutoConnect() // disable auto-connection
        .setExtraHeaders({'Authorization': 'Bearer $token'})
        .setAuth({'token': token})
        .build();
    _socket = IO.io(
      uri,
      option,
    );
  }

  String getAccessToken() {
    return _accessToken!; // throws exception if null
  }

  IO.Socket getSocket() {
    return _socket!;
  }

  void connectSocket() {
    final socket = _socket!;
    if (!socket.connected) {
      socket.onConnect((_) {
        debugPrint('connect');
        socket.emit('msg', 'test');
      });
      socket.onDisconnect((_) => debugPrint('disconnect'));
      socket.connect();
    } else {
      debugPrint('Socket already connected');
    }
  }

  bool hasAccessToken() {
    return _accessToken != null;
  }

  void clearAccessToken() {
    _accessToken = null;
  }
}
