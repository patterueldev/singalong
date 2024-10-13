import 'package:connectfeature/connectfeature.dart';
import 'package:controller_web/coordinator/app_coordinator.dart';
import 'package:controller_web/splash/splash_screen.dart';
import 'package:controller_web/splash/splash_viewmodel.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;

import 'package:provider/provider.dart';

Route<dynamic>? onGenerateRoute(RouteSettings settings, BuildContext context) {
  final uri = Uri.parse(settings.name ?? '');
  debugPrint('onGenerateRoute: ${uri.path}');
  debugPrint('onGenerateRoute queryParameters: ${uri.queryParameters}');
  html.window.history.pushState(null, '', uri.path);

  if (uri.path == '/') {
    return MaterialPageRoute(
      builder: (context) => ChangeNotifierProvider<SplashScreenViewModel>(
        create: (_) => DefaultSplashScreenViewModel(),
        child: const SplashScreen(),
      ),
    );
  }

  if (uri.path == '/connect') {
    final connectProvider = context.read<ConnectFeatureProvider>();
    return MaterialPageRoute(
      builder: (context) => connectProvider.buildConnectView(
        context: context,
        coordinator: context.read(),
        localizations: context.read(),
        assets: context.read(),
      ),
    );
  }

  if (uri.path == '/home') {
    return MaterialPageRoute(builder: (context) => Container());
  }
  return null;
}
