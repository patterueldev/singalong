import 'package:controller/splash/splash_coordinator.dart';
import 'package:controller/splash/splash_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.flow});

  final SplashFlowCoordinator flow;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  SplashFlowCoordinator get flow => widget.flow;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel =
          Provider.of<SplashScreenViewModel>(context, listen: false);
      viewModel.didFinishStateNotifier.addListener(() {
        switch (viewModel.didFinishStateNotifier.value) {
          case FinishState.unauthenticated:
            flow.onUnauthenticated(context,
                username: viewModel.username, roomId: viewModel.roomId);
            break;
          case FinishState.authenticated:
            flow.onAuthenticated(context);
            break;
          case FinishState.none:
            break;
        }
      });

      viewModel.load();
    });
  }

  @override
  Widget build(BuildContext context) => Consumer<SplashScreenViewModel>(
        builder: (context, viewModel, child) => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
}
