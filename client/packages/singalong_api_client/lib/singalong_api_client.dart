library singalong_api_client;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

part 'singalong_api_client.g.dart';
part 'api_path.dart';
part 'api_session_manager.dart';
part 'singalong_api_configuration.dart';
part 'singalong_api_client_provider.dart';
part 'models/generic_response.dart';
part 'models/connect_parameters.dart';
part 'models/connect_response.dart';
part 'models/reserved_song.dart';

class SingalongAPIClient {
  final Client _client;
  // final IO.Socket _socket;
  final APISessionManager _sessionManager;
  final SingalongAPIConfiguration _configuration;

  SingalongAPIClient({
    required Client client,
    // required IO.Socket socket,
    required APISessionManager sessionManager,
    required SingalongAPIConfiguration configuration,
  })  : _configuration = configuration,
        _sessionManager = sessionManager,
        // _socket = socket,
        _client = client;

  Future<APIConnectResponseData> connect(
      APIConnectParameters parameters) async {
    try {
      final base = _configuration.apiBaseUrl;
      final raw = "$base${APIPath.sessionConnect.value}";
      final postUri = Uri.parse(raw);
      final bodyEncoded = jsonEncode(parameters.toJson());
      final response = await _client.post(postUri,
          headers: {'Content-Type': 'application/json'}, body: bodyEncoded);
      debugPrint("Connect response: ${response.body}");
      final result = GenericResponse.fromResponse(response);
      debugPrint("Connect response: $result");
      if (result.status < 200 || result.status >= 300) {
        throw Exception(result.message ?? "Unknown error");
      }

      final data = APIConnectResponseData.fromJson(result.objectData());
      debugPrint("Connect response: $data");
      return data;
    } catch (e) {
      debugPrint("Connect error: $e");
      rethrow;
    }
  }

  // listen to reserved songs list from server
  Stream<List<APIReservedSong>> listenReservedSongs() {
    final socket = _sessionManager.getSocket();
    if (socket.hasListeners('reservedSong')) {
      throw Exception();
    }

    final controller = StreamController<List<APIReservedSong>>();
    socket.on('reservedSongs', (data) {
      final reservedSongs = APIReservedSong.fromList(data);
      controller.add(reservedSongs);
    });
    return controller.stream;
  }

  String thumbnailURL(String path) {
    String host = _configuration.host;
    return "http://$host:9000/$path";
  }
}
