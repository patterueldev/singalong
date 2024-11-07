part of '../adminfeature.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.coordinator,
  });

  final AdminCoordinator coordinator;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  SignInViewModel get viewModel => context.read();
  AdminCoordinator get coordinator => widget.coordinator;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.toastMessage.addListener(_toastMessageListener);
      viewModel.isSignedIn.addListener(_isSignedInListener);
    });
  }

  void _toastMessageListener() {
    final message = viewModel.toastMessage.value;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _isSignedInListener() {
    debugPrint('isSignedInListener: ${viewModel.isSignedIn.value}');
    if (viewModel.isSignedIn.value) {
      coordinator.onSignInSuccess(context);
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<SignInViewModel>(
        builder: (context, viewModel, child) => _build(context, viewModel),
      );

  Widget _build(BuildContext context, SignInViewModel viewModel) => Stack(
        children: [
          Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Sign in',
                        style: TextStyle(fontSize: 24),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: viewModel.usernameController,
                        decoration:
                            const InputDecoration(labelText: 'Username'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: viewModel.passwordController,
                        decoration:
                            const InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => viewModel.signIn(),
                        child: const Text('Sign in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ValueListenableBuilder(
              valueListenable: viewModel.isLoading,
              builder: (context, isLoading, child) {
                if (isLoading) {
                  return Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
        ],
      );
}
