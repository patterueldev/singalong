part of 'connectfeature.dart';

class ConnectView extends StatefulWidget {
  const ConnectView({
    super.key,
    required this.viewModel,
    required this.coordinator,
    required this.localizations,
  });

  final ConnectViewModel viewModel;
  final ConnectNavigationCoordinator coordinator;
  final ConnectLocalizations localizations;

  @override
  State<ConnectView> createState() => _ConnectViewState();
}

class _ConnectViewState extends State<ConnectView> {
  ConnectViewModel get viewModel => widget.viewModel;
  ConnectNavigationCoordinator get delegate => widget.coordinator;
  ConnectLocalizations get localizable => widget.localizations;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: localizable.screenTitleText.localizedTextOf(context),
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            ),
            body: _buildBody(context, viewModel),
          ),
          ValueListenableBuilder(
            valueListenable: viewModel.stateNotifier,
            builder: (_, state, child) {
              if (state.type == ConnectViewStateType.connecting) {
                return Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                );
              }
              if (state is Failure) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error.localizedOf(context)),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                });
              }
              if (state.type == ConnectViewStateType.connected) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: localizable.connectionSuccess
                          .localizedTextOf(context),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                  Future.delayed(const Duration(seconds: 2), () {
                    delegate.openSession(context);
                  });
                });
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      );

  Widget _buildBody(BuildContext context, ConnectViewModel viewModel) =>
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: viewModel.nameController,
                decoration: InputDecoration(
                  labelText:
                      localizable.namePlaceholderText.localizedOf(context),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: viewModel.sessionIdController,
                decoration: InputDecoration(
                  labelText:
                      localizable.sessionIdPlaceholderText.localizedOf(context),
                ),
              ),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  final buttonWidth = constraints.maxWidth * 0.5 < 250
                      ? constraints.maxWidth * 0.5
                      : 250.0;
                  return Column(
                    children: [
                      SizedBox(
                        width: buttonWidth,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => viewModel.connect(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: localizable.connectButtonText
                              .localizedTextOf(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: buttonWidth,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => viewModel.clear(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Theme.of(context).colorScheme.secondary),
                            foregroundColor:
                                Theme.of(context).colorScheme.secondary,
                          ),
                          child: localizable.clearButtonText
                              .localizedTextOf(context),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );

  @override
  void dispose() {
    viewModel.nameController.dispose();
    viewModel.sessionIdController.dispose();
    super.dispose();
  }
}
