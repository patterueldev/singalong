import 'package:flutter/material.dart';

enum AppRoute {
  initial,
  sessionConnect,
  session,
  songBook,
  download,
  identifiedSongDetails,
  notFound,
  ;

  String get path {
    switch (this) {
      case AppRoute.initial:
        return '/';
      case AppRoute.sessionConnect:
        return '/session/connect';
      case AppRoute.session:
        return '/session/active';
      case AppRoute.songBook:
        return '/session/active/songbook';
      case AppRoute.download:
        return '/session/active/songbook/download';
      case AppRoute.identifiedSongDetails:
        return '/session/active/songbook/identified-song-details';
      case AppRoute.notFound:
        return '/404';
    }
  }

  void pushReplacement(BuildContext context, {Object? arguments}) {
    Navigator.of(context).pushReplacementNamed(path, arguments: arguments);
  }

  void push(BuildContext context) {
    Navigator.of(context).pushNamed(path);
  }

  static AppRoute fromPath(String path) => AppRoute.values.firstWhere(
        (element) => element.path == path,
        orElse: () => AppRoute.notFound,
      );
}
