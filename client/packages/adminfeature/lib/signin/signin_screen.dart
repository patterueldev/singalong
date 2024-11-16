part of '../adminfeature.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({
    super.key,
    required this.coordinator,
    required this.localizations,
  });

  final AdminCoordinator coordinator;
  final AdminLocalizations localizations;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  SignInViewModel get viewModel => context.read();
  AdminCoordinator get coordinator => widget.coordinator;
  AdminLocalizations get localizations => widget.localizations;

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
                      // field for the server address
                      const SizedBox(height: 16),
                      ValueListenableBuilder(
                        valueListenable:
                            viewModel.singalongConfigurationNotifier,
                        builder: (_, configuration, __) => InkWell(
                          customBorder: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onTap: () => showDialog(
                            context: context,
                            builder: (context) => _showEditCustomHostDialog(
                                context, configuration),
                          ),
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text(
                                configuration.apiBaseUrl,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      decoration: TextDecoration.underline,
                                    ),
                              ),
                            ),
                          ),
                        ),
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

  Widget _showEditCustomHostDialog(
      BuildContext context, SingalongConfiguration configuration) {
    final hostController = TextEditingController(text: configuration.host);
    final portController =
        TextEditingController(text: configuration.apiPort.toString());

    return AlertDialog(
      title: Text(localizations.editServerHostDialogTitle.localizedOf(context)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: hostController,
            decoration: InputDecoration(
              labelText:
                  localizations.serverHostPlaceholderText.localizedOf(context),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: portController,
            decoration: InputDecoration(
              labelText: "Port",
            ),
            readOnly: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.cancelButtonText.localizedOf(context)),
        ),
        TextButton(
          onPressed: () {
            viewModel.updateServerHost(hostController.text);
            Navigator.of(context).pop();
          },
          child: Text(localizations.saveButtonText.localizedOf(context)),
        ),
        TextButton(
          onPressed: () => {
            viewModel.resetServerHost(),
            Navigator.of(context).pop(),
          },
          child: Text(localizations.clearButtonText.localizedOf(context)),
        ),
      ],
    );
  }
}
