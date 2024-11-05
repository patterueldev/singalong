import 'package:flutter/material.dart';

abstract class SplashFlowCoordinator {
  void onAuthenticated(BuildContext context, {String? redirectPath});
  void onUnauthenticated(BuildContext context);
}
