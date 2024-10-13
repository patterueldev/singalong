import 'package:flutter/material.dart';

enum FinishState {
  none,
  authenticated,
  unauthenticated,
}

abstract class SplashScreenViewModel extends ChangeNotifier {
  ValueNotifier<FinishState> get didFinishStateNotifier;

  void load();
}

class DefaultSplashScreenViewModel extends SplashScreenViewModel {
  @override
  final ValueNotifier<FinishState> didFinishStateNotifier =
      ValueNotifier(FinishState.none);

  @override
  void load() async {
    await Future.delayed(const Duration(seconds: 2));
    didFinishStateNotifier.value = FinishState.unauthenticated;
  }
}
