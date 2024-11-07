import 'package:controller/web/approute.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart';

abstract class SplashScreenViewModel extends ChangeNotifier {
  ValueNotifier<SplashState> get didFinishStateNotifier;
  void load();
}

class SplashState {
  final SplashStatus status;

  SplashState(this.status);

  factory SplashState.idle() => SplashState(SplashStatus.idle);
  factory SplashState.checking() => SplashState(SplashStatus.checking);
  factory SplashState.unauthenticated() =>
      SplashState(SplashStatus.unauthenticated);
  factory SplashState.authenticated(AppRoute? redirectRoute) =>
      AuthenticatedState(redirectRoute);
}

class AuthenticatedState extends SplashState {
  final AppRoute? redirectRoute;
  AuthenticatedState(this.redirectRoute) : super(SplashStatus.authenticated);
}

enum SplashStatus {
  idle,
  checking,
  authenticated,
  unauthenticated,
}
