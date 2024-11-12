part of 'core.dart';

abstract class SingalongConfiguration {
  String get defaultHost;
  String? customHost;

  String protocol = "http";
  String get host => customHost ?? defaultHost;
  int apiPort = 8080;
  int socketPort = 9092;
  int storagePort = 9000;

  String get apiBaseUrl => "http://$host:$apiPort";
  String get socketBaseUrl => "http://$host:$socketPort";
  String get storageBaseUrl => "http://$host:$storagePort";

  String get persistenceStorageKey;

  Uri buildURL(String path, {Map<String, dynamic>? queryParameters}) {
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

  Uri buildSocketURL(String path) {
    final filterBaseUrl = socketBaseUrl.removeSuffix("/");
    final filteredPath = path.removePrefix("/");
    return Uri.parse("$filterBaseUrl/$filteredPath");
  }

  Uri buildResourceURL(String path) {
    final filterBaseUrl = storageBaseUrl.removeSuffix("/");
    final filteredPath = path.removePrefix("/");
    return Uri.parse("$filterBaseUrl/$filteredPath");
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