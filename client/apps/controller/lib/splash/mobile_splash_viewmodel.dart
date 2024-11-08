import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart';

import 'splash_viewmodel.dart';

class MobileSplashScreenViewModel extends SplashScreenViewModel {
  final ConnectRepository connectRepository;
  final PersistenceRepository persistenceService;

  MobileSplashScreenViewModel({
    required this.connectRepository,
    required this.persistenceService,
  });

  @override
  final ValueNotifier<SplashState> didFinishStateNotifier =
      ValueNotifier(SplashState.idle());

  @override
  void load() async {
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
