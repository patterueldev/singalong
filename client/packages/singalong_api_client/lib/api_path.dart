part of 'singalong_api_client.dart';

enum APIPath {
  sessionConnect,
  songs;

  String get value {
    switch (this) {
      case sessionConnect:
        return '/session/connect';
      case songs:
        return '/songs';
    }
  }
}
