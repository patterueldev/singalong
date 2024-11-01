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
part 'models/current_song.dart';
part 'models/song.dart';

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

  Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_sessionManager.getAccessToken()}',
    };
  }

  Future<APIConnectResponseData> connect(
      APIConnectParameters parameters) async {
    try {
      final postUri =
          _configuration.buildEndpoint(APIPath.sessionConnect.value);
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

  Future<APIPaginatedSongs> loadSongs(APILoadSongsParameters parameters) async {
    try {
      final query = parameters.toJson();
      final getUri = _configuration.buildEndpoint(APIPath.songs.value,
          queryParameters: query);
      debugPrint("loadSongs: $getUri");
      final response = await _client.get(getUri, headers: getHeaders());
      final result = GenericResponse.fromResponse(response);
      if (result.status < 200 || result.status >= 300) {
        throw Exception(result.message ?? "Unknown error");
      }

      final data = APIPaginatedSongs.fromJson(result.objectData());
      return data;
    } catch (e) {
      if (e is ClientException) {
        debugPrint("loadSongs error: ${e.message}");
      }
      debugPrint("loadSongs error: $e");
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

  // listen to current song from server
  Stream<APICurrentSong?> listenCurrentSong() {
    debugPrint("listenCurrentSong");
    final socket = _sessionManager.getSocket();
    if (socket.hasListeners('currentSong')) {
      throw Exception();
    }

    final controller = StreamController<APICurrentSong?>();
    socket.on('currentSong', (data) {
      if (data == null) {
        controller.add(null);
        return;
      }
      final currentSong = APICurrentSong.fromJson(data);
      controller.add(currentSong);
    });
    return controller.stream;
  }

  String resourceURL(String path) {
    String host = _configuration.host;
    // TODO: port will be configurable
    return "http://$host:9000/$path";
  }
}
