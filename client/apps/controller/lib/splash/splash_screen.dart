import 'package:controller/splash/splash_coordinator.dart';
import 'package:controller/splash/splash_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.flow});

  final SplashFlowCoordinator? flow;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  SplashFlowCoordinator? get flow => widget.flow;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel =
          Provider.of<SplashScreenViewModel>(context, listen: false);
      viewModel.didFinishStateNotifier.addListener(() {
        final state = viewModel.didFinishStateNotifier.value;
        if (state.status == SplashStatus.idle) return;
        if (state.status == SplashStatus.checking) return;
        if (state.status == SplashStatus.unauthenticated) {
          flow?.onUnauthenticated(context);
        }
        if (state is AuthenticatedState) {
          flow?.onAuthenticated(context,
              redirectPath: state.redirectRoute?.path);
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
