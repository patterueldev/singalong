// ignore_for_file: avoid_web_libraries_in_flutter
// This is a web-specific file and should not have any Flutter-specific code.

import 'package:common/common.dart';
import 'package:controller/web/approute.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';

import 'dart:html' as html;
import 'splash_viewmodel.dart';

class WebSplashScreenViewModel extends SplashScreenViewModel {
  final ConnectRepository connectRepository;
  final PersistenceRepository
      persistenceService; // Might need this when restoring authentication
  final SingalongConfiguration configuration;

  WebSplashScreenViewModel({
    required this.connectRepository,
    required this.persistenceService,
    required this.configuration,
  });

  @override
  final ValueNotifier<SplashState> didFinishStateNotifier =
      ValueNotifier(SplashState.idle());

  @override
  void load() async {
    try {
      // will have to check if query contained custom configurations like these
      configuration.customProtocol =
          await persistenceService.getString(PersistenceKey.customApiProtocol);

      configuration.customApiHost =
          await persistenceService.getString(PersistenceKey.customApiHost);
      configuration.customApiPort =
          await persistenceService.getInt(PersistenceKey.customApiPort);
      configuration.customSocketHost =
          await persistenceService.getString(PersistenceKey.customSocketHost);
      configuration.customSocketPort =
          await persistenceService.getInt(PersistenceKey.customSocketPort);
      configuration.customStorageHost =
          await persistenceService.getString(PersistenceKey.customStorageHost);
      configuration.customStoragePort =
          await persistenceService.getInt(PersistenceKey.customStoragePort);

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
      final isAuthenticated = await connectRepository.checkAuthentication();
      if (isAuthenticated) {
        didFinishStateNotifier.value = SplashState.authenticated(null);
      } else {
        didFinishStateNotifier.value = SplashState.unauthenticated();
      }
    } catch (e) {
      debugPrint("Error while loading: $e");
    }
  }
}
