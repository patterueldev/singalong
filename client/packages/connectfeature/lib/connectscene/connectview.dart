part of '../connectfeature.dart';

class ConnectView extends StatefulWidget {
  const ConnectView({
    super.key,
    required this.flow,
    required this.localizations,
    required this.assets,
  });

  final ConnectFlowCoordinator flow;
  final ConnectLocalizations localizations;
  final ConnectAssets assets;

  @override
  State<ConnectView> createState() => _ConnectViewState();
}

class _ConnectViewState extends State<ConnectView> {
  ConnectViewModel get viewModel => context.read<ConnectViewModel>();
  ConnectFlowCoordinator get flow => widget.flow;
  ConnectLocalizations get localizations => widget.localizations;
  ConnectAssets get assets => widget.assets;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.stateNotifier.addListener(_stateListener);
      viewModel.load();
    });
  }

  @override
  void dispose() {
    viewModel.stateNotifier.removeListener(_stateListener);
    viewModel.nameController.dispose();
    viewModel.sessionIdController.dispose();
    super.dispose();
  }

  void _stateListener() {
    final state = viewModel.stateNotifier.value;

    if (state is Failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              state.error.localizedFrom(localizations).localizedTextOf(context),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    if (state.status == ConnectViewStatus.connected) {
      flow.onConnected(context);
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<ConnectViewModel>(
        builder: (context, viewModel, _) => Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              ),
              body: SingleChildScrollView(
                child: _buildBody(context, viewModel),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: viewModel.stateNotifier,
              builder: (_, state, child) {
                if (state.status == ConnectViewStatus.connecting) {
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
              },
            ),
          ],
        ),
      );

  Widget _buildBody(BuildContext context, ConnectViewModel viewModel) =>
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 50),
            assets.connectBannerImage.image(height: 250),
            TextField(
              controller: viewModel.nameController,
              decoration: InputDecoration(
                labelText:
                    localizations.namePlaceholderText.localizedOf(context),
                icon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: viewModel.sessionIdController,
              decoration: InputDecoration(
                labelText:
                    localizations.sessionIdPlaceholderText.localizedOf(context),
                icon: const Icon(Icons.meeting_room),
              ),
            ),
            // field for the server address
            const SizedBox(height: 16),
            ValueListenableBuilder(
              valueListenable: viewModel.singalongConfigurationNotifier,
              builder: (_, configuration, __) => InkWell(
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onTap: () => showDialog(
                  context: context,
                  builder: (context) =>
                      _showEditCustomHostDialog(context, configuration),
                ),
                child: IgnorePointer(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      configuration.apiBaseUrl,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                ),
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
                        child: localizations.connectButtonText
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
                        child: localizations.clearButtonText
                            .localizedTextOf(context),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
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
