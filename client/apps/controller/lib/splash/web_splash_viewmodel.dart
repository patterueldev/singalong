import 'package:controller/web/approute.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'dart:html' as html;
import 'splash_viewmodel.dart';

class WebSplashScreenViewModel extends SplashScreenViewModel {
  final PersistenceService
      persistenceService; // Might need this when restoring authentication

  WebSplashScreenViewModel({required this.persistenceService});

  @override
  final ValueNotifier<SplashState> didFinishStateNotifier =
      ValueNotifier(SplashState.idle());

  @override
  void load() async {
    try {
      // check current address from browser
      final uri = html.window.location.href;
      final path = html.window.location.pathname;
      debugPrint("Current address: $uri");
      debugPrint("Current path: $path");
      final route = AppRoute.fromPath(path!);
      if (route == AppRoute.sessionConnect) {
        // no need to check for authentication
        return;
      }
    } catch (e) {
      debugPrint("Error while loading: $e");
    }
    await Future.delayed(const Duration(seconds: 2));
    didFinishStateNotifier.value = SplashState.unauthenticated();
  }
}