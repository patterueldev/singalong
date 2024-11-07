import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart';

import 'splash_viewmodel.dart';

class MobileSplashScreenViewModel extends SplashScreenViewModel {
  final PersistenceRepository persistenceService;

  MobileSplashScreenViewModel({required this.persistenceService});

  @override
  final ValueNotifier<SplashState> didFinishStateNotifier =
      ValueNotifier(SplashState.idle());

  @override
  void load() async {
    await Future.delayed(const Duration(seconds: 2));
    didFinishStateNotifier.value = SplashState.unauthenticated();
  }
}
