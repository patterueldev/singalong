part of 'singalong_api_client.dart';

enum APIPath {
  sessionConnect;

  String get value {
    switch (this) {
      case sessionConnect:
        return '/session/connect';
    }
  }
}
