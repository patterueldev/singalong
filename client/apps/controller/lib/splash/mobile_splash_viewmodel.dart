import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart';

import 'splash_viewmodel.dart';

class MobileSplashScreenViewModel extends SplashScreenViewModel {
  final ConnectRepository connectRepository;
  final PersistenceRepository persistenceService;
  final SingalongConfiguration configuration;

  MobileSplashScreenViewModel({
    required this.connectRepository,
    required this.persistenceService,
    required this.configuration,
  });

  @override
  final ValueNotifier<SplashState> didFinishStateNotifier =
      ValueNotifier(SplashState.idle());

  @override
  void load() async {
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

    debugPrint('MobileSplashScreenViewModel.load()');
    final isAuthenticated = await connectRepository.checkAuthentication();
    debugPrint(
        'MobileSplashScreenViewModel.load() isAuthenticated: $isAuthenticated');
    if (isAuthenticated) {
      didFinishStateNotifier.value = SplashState.authenticated(null);
    } else {
      didFinishStateNotifier.value = SplashState.unauthenticated();
    }
  }
}
