import 'package:controller/splash/splash_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';

import 'mobile_splash_viewmodel.dart';
import 'splash_screen.dart';
import 'splash_viewmodel.dart';

// class SplashProvider {
//   final SplashFlowCoordinator coordinator;
//   final PersistenceService persistenceService;
//
//   const SplashProvider({
//     required this.coordinator,
//     required this.persistenceService,
//   });
//
//   Widget buildSplashScreen(
//     BuildContext context, {
//     String? username,
//     String? roomId,
//   }) =>
//       ChangeNotifierProvider<SplashScreenViewModel>(
//         create: (_) => DefaultSplashScreenViewModel(
//           persistenceService: persistenceService,
//           username: username,
//           roomId: roomId,
//         ),
//         child: SplashScreen(flow: coordinator),
//       );
// }
