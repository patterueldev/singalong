import 'package:controller/splash/splash_provider.dart';
import 'package:controller/web/approute.dart';
import 'package:controller/web/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../splash/splash_screen.dart';
import '../splash/splash_viewmodel.dart';
import 'on_generate_routes.dart';

class ControllerWebApp extends StatefulWidget {
  const ControllerWebApp({super.key});

  @override
  State<ControllerWebApp> createState() => _ControllerWebAppState();
}

class _ControllerWebAppState extends State<ControllerWebApp> {
  // @override
  // void initState() {
  //   super.initState();
  //
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     final viewModel = context.read<AppViewModel>();
  //     viewModel.appState.addListener(_onAuthenticationChanged);
  //     viewModel.checkAuthentication();
  //   });
  // }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Singalong',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.greenAccent),
          useMaterial3: true,
        ),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        routes: routes,
        onGenerateRoute: (settings) => onGenerateRoute(settings, context),
      );

  // void _onAuthenticationChanged() {
  //   final viewModel = context.read<AppViewModel>();
  //   final isAuthenticated = viewModel.appState.value == AppState.authenticated;
  //   debugPrint('isAuthenticated: $isAuthenticated');
  //   if (!isAuthenticated) {
  //     AppRoute.sessionConnect.pushReplacement(context);
  //   } else {}
  // }
}

// abstract class AppViewModel extends ChangeNotifier {
//   ValueNotifier<AppState> appState = ValueNotifier(AppState.loading);
//   void checkAuthentication();
// }
//
// class AppViewModelImpl extends AppViewModel {
//   AppViewModelImpl();
//
//   @override
//   void checkAuthentication() async {
//     debugPrint('Checking authentication...');
//     await Future.delayed(const Duration(seconds: 2));
//     appState.value = AppState.unauthenticated;
//   }
// }
//
// enum AppState {
//   loading,
//   unauthenticated,
//   authenticated,
// }
