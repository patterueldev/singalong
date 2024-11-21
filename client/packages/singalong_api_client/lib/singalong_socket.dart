part of 'singalong_api_client.dart';

class SingalongSocket {
  final SingalongConfiguration configuration;
  final APISessionManager sessionManager;

  SingalongSocket({
    required this.configuration,
    required this.sessionManager,
  });

  IO.Socket? _idleSocket;
  IO.Socket? _roomSocket;

  // IDLE SOCKET

  Future<void> connectIdleSocket(String name, String deviceId) async {
    final completer = Completer<bool>();
    if (_idleSocket != null) {
      throw Exception("Idle socket already initialized");
    }
    final uri = configuration.buildSocketURL("idle");
    final option = IO.OptionBuilder()
        .setTransports(['websocket']) // for Flutter or Dart VM
        .setExtraHeaders({
      'playerName': name,
      'deviceId': deviceId,
    }).build();
    _idleSocket = IO.io(uri.toString(), option);
    _idleSocket?.onConnect((_) async {
      debugPrint('connected to idle socket');
      // give a bit of time to check if the socket gets disconnected
      await Future.delayed(const Duration(seconds: 2));
      if (!completer.isCompleted) completer.complete(true);
    });
    _idleSocket?.onDisconnect((_) {
      debugPrint('disconnect from idle socket');
      if (!completer.isCompleted) completer.complete(false);
    });
    _idleSocket?.connect();

    final result = await completer.future;
    if (!result) {
      throw Exception("Disconnected from the socket");
    }
  }

  void disconnectIdleSocket() {
    _idleSocket?.disconnect();
  }

  // ROOM SOCKET

  Future<void> connectRoomSocket(String roomId) async {
    final isSignedIn = sessionManager.hasAccessToken();
    if (!isSignedIn) {
      throw Exception("Not signed in");
    }

    final completer = Completer<bool>();
    _roomSocket?.disconnect();
    final uri = configuration.buildSocketURL("room/$roomId");
    final option = IO.OptionBuilder()
        .setTransports(['websocket']) // for Flutter or Dart VM
        .setAuth({'token': sessionManager.getAccessToken()}).build();
    _roomSocket = IO.io(uri.toString(), option);
    _roomSocket?.onConnect((_) async {
      debugPrint('connected to room socket $roomId');
      // give a bit of time to check if the socket gets disconnected
      await Future.delayed(const Duration(seconds: 2));
      if (!completer.isCompleted) completer.complete(true);
    });
    _roomSocket?.onDisconnect((_) {
      debugPrint('disconnect from room socket');
      if (!completer.isCompleted) completer.complete(false);
    });
    _roomSocket?.connect();

    final result = await completer.future;
    if (!result) {
      throw Exception("Disconnected from the socket");
    }
  }

  void disconnectRoomSocket() {
    _roomSocket?.disconnect();
  }

  StreamController<T> _buildEventStreamController<T>(SocketEvent event,
      IO.Socket socket, Function(dynamic, StreamController<T>) handler) {
    if (socket.hasListeners(event.value)) {
      throw Exception("Already listening to ${event.value}");
    }
    final controller = StreamController<T>(
      onCancel: () {
        socket.off(event.value);
      },
    );
    socket.on(event.value, (data) {
      handler(data, controller);
    });
    return controller;
  }

  StreamController<T> buildIdleEventStreamController<T>(
          SocketEvent event, Function(dynamic, StreamController<T>) handler) =>
      _buildEventStreamController(
        event,
        _idleSocket!,
        handler,
      );

  StreamController<T> buildRoomEventStreamController<T>(
          SocketEvent event, Function(dynamic, StreamController<T>) handler) =>
      _buildEventStreamController(
        event,
        _roomSocket!,
        handler,
      );

  void emitIdleEvent(SocketEvent event, dynamic data) {
    debugPrint('Emitting idle event: ${event.value} with data: $data');
    _idleSocket?.emit(event.value, data);
  }

  void emitRoomEvent(SocketEvent event, dynamic data) {
    debugPrint('Emitting event: ${event.value} with data: $data');
    _roomSocket?.emit(event.value, data);
  }

  void emitRoomDataRequestEvent(List<RoomDataType> dataTypes) {
    final dataTypesRaw = dataTypes.map((t) => t.value).join(',');
    debugPrint(
        'Emitting event: ${SocketEvent.roomDataRequest.value} with data: $dataTypesRaw');
    _roomSocket?.emit(SocketEvent.roomDataRequest.value, dataTypesRaw);
  }

  void emitRoomCommandEvent(RoomCommand command) {
    // debugPrint(
    //     'Emitting event: ${SocketEvent.roomPlayerCommand.value} with data: ${command.toJsonString()}');
    _roomSocket?.emit(
        SocketEvent.roomPlayerCommand.value, command.toJsonString());
  }
}
