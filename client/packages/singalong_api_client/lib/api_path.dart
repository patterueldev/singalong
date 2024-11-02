part of 'singalong_api_client.dart';

enum APIPath {
  sessionConnect,
  songs,
  reserveSong;

  String get value {
    switch (this) {
      case sessionConnect:
        return '/session/connect';
      case songs:
        return '/songs';
      case reserveSong:
        return '/songs/reserve';
    }
  }
}
