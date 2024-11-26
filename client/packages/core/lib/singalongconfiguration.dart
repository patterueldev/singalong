part of 'core.dart';

abstract class SingalongConfiguration {
  String get defaultApiHost;
  String get defaultSocketHost => defaultApiHost;
  String get defaultStorageHost => defaultApiHost;

  String get defaultProtocol => "http";

  int get defaultApiPort => 8080;
  int get defaultSocketPort => 8005;
  int get defaultStoragePort => 8005;

  String? customApiHost;
  String?
      customSocketHost; // I think this will still work with API host because it lives in the same server
  String? customStorageHost;

  String?
      customProtocol; // might want to also spread this to socket and storage

  int? customApiPort;
  int? customSocketPort;
  int? customStoragePort;

  String get protocol => customProtocol ?? defaultProtocol;

  String get apiHost => customApiHost ?? defaultApiHost;
  String get socketHost => customSocketHost ?? defaultSocketHost;
  String get storageHost => customStorageHost ?? defaultStorageHost;

  int get apiPort => customApiPort ?? defaultApiPort;
  int get socketPort => customSocketPort ?? defaultSocketPort;
  int get storagePort => customStoragePort ?? defaultStoragePort;

  String baseUrlBuilder(String protocol, String host, int port,
      {String suffix = ""}) {
    String urlPort = "";
    if (port != 80) {
      urlPort = ":$port";
    }
    return "$protocol://$host$urlPort$suffix";
  }

  // String get apiBaseUrl => "$protocol://$apiHost:$apiPort";
  String get apiBaseUrl => baseUrlBuilder(protocol, apiHost, apiPort);
  String get socketBaseUrl => baseUrlBuilder(protocol, socketHost, socketPort);
  String get storageBaseUrl =>
      baseUrlBuilder(protocol, storageHost, storagePort, suffix: "/storage");

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

  Uri buildProxyURL(String url) {
    final filterBaseUrl = apiBaseUrl.removeSuffix("/");
    final encodedUrl = Uri.encodeComponent(url);
    return Uri.parse("$filterBaseUrl/source-image?url=$encodedUrl");
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
