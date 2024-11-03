import 'package:flutter/material.dart';

abstract class SplashFlowCoordinator {
  void onAuthenticated(BuildContext context);
  void onUnauthenticated(
    BuildContext context, {
    String? username,
    String? roomId,
  });
}
