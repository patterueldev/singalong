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
part 'models/identified_song_details.dart';
part 'models/save_song_parameters.dart';
part 'models/save_song_response.dart';
part 'models/downloadable_item.dart';

enum HttpMethod { GET, POST, PATCH, PUT, DELETE }

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

  Future<GenericResponse> request({
    required Uri uri,
    required HttpMethod method,
    Map<String, dynamic>? payload,
    bool requireAuth = true,
  }) async {
    try {
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      if (requireAuth) {
        headers = getHeaders();
      }
      final bodyEncoded = payload != null ? jsonEncode(payload) : null;
      debugPrint("request: $method $uri");
      debugPrint("request headers: $headers");
      debugPrint("request body: $bodyEncoded");
      Response response;
      switch (method) {
        case HttpMethod.GET:
          response = await _client.get(uri, headers: headers);
          break;
        case HttpMethod.POST:
          response =
              await _client.post(uri, headers: headers, body: bodyEncoded);
          break;
        case HttpMethod.PATCH:
          response =
              await _client.patch(uri, headers: headers, body: bodyEncoded);
          break;
        case HttpMethod.PUT:
          response =
              await _client.put(uri, headers: headers, body: bodyEncoded);
          break;
        case HttpMethod.DELETE:
          response = await _client.delete(uri, headers: headers);
          break;
        default:
          throw Exception("Unsupported method: $method");
      }
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint("request response body: $decodedBody");
      try {
        final result = GenericResponse.fromResponse(response);
        debugPrint("request result: $result");
        if (result.status < 200 || result.status >= 300) {
          throw Exception(result.message ?? "Unknown error");
        }
        return result;
      } catch (e, st) {
        debugPrint("request error: $e");
        debugPrint("request stacktrace: $st");
        final message = "Response body: ${response.body}";
        throw Exception(message);
      }
    } catch (e, st) {
      debugPrint("request error: $e");
      debugPrint("request stacktrace: $st");
      rethrow;
    }
  }

  Future<APIConnectResponseData> connect(
      APIConnectParameters parameters) async {
    final postUri = _configuration.buildEndpoint(APIPath.sessionConnect.value);
    final result = await request(
      uri: postUri,
      method: HttpMethod.POST,
      payload: parameters.toJson(),
      requireAuth: false,
    );
    return APIConnectResponseData.fromJson(result.objectData());
  }

  Future<APIPaginatedSongs> loadSongs(APILoadSongsParameters parameters) async {
    final query = parameters.toJson();
    final getUri = _configuration.buildEndpoint(APIPath.songs.value,
        queryParameters: query);
    final result = await request(
      uri: getUri,
      method: HttpMethod.GET,
      payload: parameters.toJson(),
    );
    return APIPaginatedSongs.fromJson(result.objectData());
  }

  Future<void> reserveSong(APIReserveSongParameters parameters) async {
    final postUri = _configuration.buildEndpoint(APIPath.reserveSong.value);
    await request(
      uri: postUri,
      method: HttpMethod.POST,
      payload: parameters.toJson(),
    );
  }

  Future<APIIdentifiedSongDetails> identifySong(
      APIIdentifySongParameters parameters) async {
    final postUri = _configuration.buildEndpoint(APIPath.identifySong.value);
    final result = await request(
      uri: postUri,
      method: HttpMethod.POST,
      payload: parameters.toJson(),
    );
    return APIIdentifiedSongDetails.fromJson(result.objectData());
  }

  Future<APISaveSongResponseData> saveSong(
      APISaveSongParameters parameters) async {
    final postUri = _configuration.buildEndpoint(APIPath.songs.value);
    final result = await request(
      uri: postUri,
      method: HttpMethod.POST,
      payload: parameters.toJson(),
    );
    return APISaveSongResponseData.fromJson(result.objectData());
  }

  Future<List<APIDownloadableData>> searchDownloadables(
      APISearchDownloadablesParameters parameters) async {
    final query = parameters.toJson();
    final getUri = _configuration.buildEndpoint(APIPath.songs.value,
        queryParameters: query);
    final result = await request(
      uri: getUri,
      method: HttpMethod.GET,
    );
    return result
        .arrayData()
        .map((e) => APIDownloadableData.fromJson(e))
        .toList();
  }

  // TODO: Move this to a separate client, maybe SingalongAPISocketClient; might as well rename this to SingalongAPIRestClient
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
