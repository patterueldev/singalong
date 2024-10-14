library singalong_api_client;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:provider/provider.dart';

part 'singalong_api_client.g.dart';
part 'api_path.dart';
part 'singalong_api_configuration.dart';
part 'models/generic_response.dart';
part 'models/connect_parameters.dart';
part 'models/connect_response.dart';
part 'models/reserved_song.dart';

class SingalongAPIClient {
  final Client client;
  final SingalongAPIConfiguration configuration;

  SingalongAPIClient({
    required this.client,
    required this.configuration,
  });

  Future<APIConnectResponseData> connect(
      APIConnectParameters parameters) async {
    try {
      final base = configuration.baseUrl;
      final raw = "$base${APIPath.sessionConnect.value}";
      final postUri = Uri.parse(raw);
      final bodyEncoded = jsonEncode(parameters.toJson());
      final response = await client.post(postUri,
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
}

class SingalongAPIClientProvider {
  final providers = MultiProvider(providers: [
    Provider<Client>(
      create: (context) => Client(),
      dispose: (context, client) => client.close(),
    ),
    Provider<SingalongAPIClient>(
      create: (context) => SingalongAPIClient(
        client: context.read(),
        configuration: context.read(),
      ),
    ),
  ]);
}

// enum ClientType {
//   ADMIN,
//   CONTROLLER,
//   PLAYER,
// }

/**
    data class ConnectParameters(
    val username: String,
    val userPasscode: String?,
    val roomId: String,
    val roomPasscode: String?,
    val clientType: ClientType,
    )

 */
