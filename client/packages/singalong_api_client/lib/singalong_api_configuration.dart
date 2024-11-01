part of 'singalong_api_client.dart';

abstract class SingalongAPIConfiguration {
  String get protocol; //TODO: Might not be needed
  String get host;
  int get apiPort;
  int get socketPort;

  String get apiBaseUrl => "http://$host:$apiPort";
  String get socketBaseUrl => "http://$host:$socketPort";

  Uri buildEndpoint(String path, {Map<String, dynamic>? queryParameters}) {
    final filterBaseUrl = apiBaseUrl.removeSuffix("/");
    final filteredPath = path.removePrefix("/");
    final raw = "$filterBaseUrl/$filteredPath";
    if (queryParameters != null) {
      List<String> queryParams = [];
      queryParameters.forEach((key, value) {
        if (value != null) {
          queryParams.add("$key=$value");
        }
      });
      final query = queryParams.join("&");
      return Uri.parse(raw).replace(query: query);
    }
    return Uri.parse(raw);
  }
}

extension RemovePrefix on String {
  String removePrefix(String prefix) {
    if (this.startsWith(prefix)) {
      return this.substring(prefix.length);
    }
    return this;
  }
}

extension RemoveSuffix on String {
  String removeSuffix(String suffix) {
    if (this.endsWith(suffix)) {
      return this.substring(0, this.length - suffix.length);
    }
    return this;
  }
}
