part of 'singalong_api_client.dart';

class SingalongSocket {
  final SingalongConfiguration configuration;
  final APISessionManager sessionManager;

  SingalongSocket({
    required this.configuration,
    required this.sessionManager,
  });

  IO.Socket? _socket;
  IO.Socket get socket => _socket!;

  void buildSocket() {
    final uri = configuration.buildSocketURL("singalong");
    final option = IO.OptionBuilder()
        .setTransports(['websocket']) // for Flutter or Dart VM
        .disableAutoConnect() // disable auto-connection
        .setExtraHeaders(
            {'Authorization': 'Bearer ${sessionManager.getAccessToken()}'})
        .setAuth({'token': sessionManager.getAccessToken()})
        .build();

    final socket = IO.io(uri.toString(), option);
    _socket = socket;
  }

  void connectSocket() {
    socket.onConnect((_) => debugPrint('connected to socket'));
    socket.onDisconnect((_) => debugPrint('disconnect from socket'));
    socket.connect();
  }

  void disconnectSocket() {
    socket.disconnect();
    _socket = null;
  }

  StreamController<T> buildEventStreamController<T>(
      SocketEvent event, Function(dynamic, StreamController<T>) handler) {
    if (socket.hasListeners(event.value)) {
      throw Exception("Already listening to ${event.value}");
    }
    final controller = StreamController<T>();
    socket.on(event.value, (data) {
      handler(data, controller);
    });
    return controller;
  }

  StreamController<List<APIReservedSong>>
      buildReservedSongsStreamController() => buildEventStreamController(
            SocketEvent.reservedSongs,
            (data, controller) {
              final reservedSongs = APIReservedSong.fromList(data);
              controller.add(reservedSongs);
            },
          );

  // listen to current song from server
  StreamController<APICurrentSong?> buildCurrentSongStreamController() =>
      buildEventStreamController(
        SocketEvent.currentSong,
        (data, controller) {
          if (data == null) {
            controller.add(null);
            return;
          }
          final currentSong = APICurrentSong.fromJson(data);
          controller.add(currentSong);
        },
      );

  // listen to seek duration from player
  StreamController<int> buildSeekDurationFromPlayerStreamController() =>
      buildEventStreamController(
        SocketEvent.seekDurationFromPlayer,
        (data, controller) {
          final seekValue = data as int;
          controller.add(seekValue);
        },
      );

  // listen to seek duration from control
  StreamController<int> buildSeekDurationFromControlStreamController() =>
      buildEventStreamController(
        SocketEvent.seekDurationFromControl,
        (data, controller) {
          final seekValue = data as int;
          controller.add(seekValue);
        },
      );

  // update seek duration to server
  void emitEvent(SocketEvent event, dynamic data) {
    socket.emit(event.value, data);
  }
}
