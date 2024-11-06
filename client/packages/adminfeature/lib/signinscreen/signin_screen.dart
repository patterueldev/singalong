part of '../adminfeature.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({Key? key});

  @override
  Widget build(BuildContext context) => Consumer<SignInViewModel>(
        builder: (context, viewModel, child) => _build(context, viewModel),
      );

  Widget _build(BuildContext context, SignInViewModel viewModel) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Sign in'),
          ElevatedButton(
            onPressed: () => viewModel.signIn(),
            child: const Text('Sign in'),
          ),
        ],
      );
}
