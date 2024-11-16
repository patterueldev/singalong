part of 'singalong_api_client.dart';

enum HttpMethod { GET, POST, PATCH, PUT, DELETE }

class APIClient {
  final Client client;
  final APISessionManager sessionManager;
  final SingalongConfiguration configuration;

  APIClient({
    required this.client,
    required this.sessionManager,
    required this.configuration,
  });

  Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${sessionManager.getAccessToken()}',
    };
  }

  Future<GenericResponse> request({
    required APIPath path,
    Map<String, dynamic>? queryParameters,
    required HttpMethod method,
    Map<String, dynamic>? payload,
    bool requireAuth = true,
  }) async {
    try {
      final uri =
          configuration.buildURL(path.value, queryParameters: queryParameters);
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
          response = await client.get(uri, headers: headers);
          break;
        case HttpMethod.POST:
          response =
              await client.post(uri, headers: headers, body: bodyEncoded);
          break;
        case HttpMethod.PATCH:
          response =
              await client.patch(uri, headers: headers, body: bodyEncoded);
          break;
        case HttpMethod.PUT:
          response = await client.put(uri, headers: headers, body: bodyEncoded);
          break;
        case HttpMethod.DELETE:
          response = await client.delete(uri, headers: headers);
          break;
        default:
          throw Exception("Unsupported method: $method");
      }
      final decodedBody = utf8.decode(response.bodyBytes);
      debugPrint("request response body: $decodedBody");
      final result = GenericResponse.fromResponse(response);
      try {
        debugPrint("request result: $result");
        if (result.status < 200 || result.status >= 300) {
          throw Exception(result.message ?? "Unknown error");
        }
        return result;
      } catch (e, st) {
        debugPrint("request error: $e");
        debugPrint("request stacktrace: $st");
        final apiMessage = result.message;
        if (apiMessage != null) {
          throw GenericException.api(apiMessage);
        } else {
          throw GenericException.unhandled(e);
        }
      }
    } catch (e, st) {
      debugPrint("request error: $e");
      debugPrint("request stacktrace: $st");
      rethrow;
    }
  }
}
