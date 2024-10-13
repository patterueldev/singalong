import 'package:controller_web/splash/splash_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel =
          Provider.of<SplashScreenViewModel>(context, listen: false);
      viewModel.didFinishStateNotifier.addListener(() {
        switch (viewModel.didFinishStateNotifier.value) {
          case FinishState.unauthenticated:
            Navigator.of(context).pushReplacementNamed('/connect');
            break;
          case FinishState.authenticated:
            Navigator.of(context).pushReplacementNamed('/home');
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
