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
                      textAlign: TextAlign.center,
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
    final ValueNotifier<String> selectedProtocolNotifier =
        ValueNotifier(configuration.protocol);

    // API host and port (also socket host and port)
    final apiHostController =
        TextEditingController(text: configuration.apiHost);
    final apiPortController =
        TextEditingController(text: configuration.apiPort.toString());

    // Storage host and port
    final storageHostController =
        TextEditingController(text: configuration.storageHost);
    final storagePortController =
        TextEditingController(text: configuration.storagePort.toString());

    final successNotifier = ValueNotifier(false);
    successNotifier.addListener(() {
      if (successNotifier.value) {
        Navigator.of(context).pop();
      }
    });

    return AlertDialog(
      title: Text(localizations.editServerHostDialogTitle.localizedOf(context)),
      content: Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              ValueListenableBuilder(
                  valueListenable: selectedProtocolNotifier,
                  builder: (_, selectedProtocol, __) {
                    return DropdownButton<String>(
                      value: selectedProtocol,
                      onChanged: (String? value) {
                        selectedProtocolNotifier.value = value ?? 'http';
                      },
                      items: ['http', 'https']
                          .map((protocol) => DropdownMenuItem<String>(
                                value: protocol,
                                child: Text(protocol),
                              ))
                          .toList(),
                    );
                  }),
              // API host and port
              TextField(
                controller: apiHostController,
                decoration: InputDecoration(
                  labelText: localizations.serverHostPlaceholderText
                      .localizedOf(context),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: apiPortController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: "API Port"),
                    ),
                  ),
                  // button to set the port to 80
                  TextButton(
                    onPressed: () {
                      apiPortController.text = '80';
                    },
                    child: Text('80?'),
                  ),
                ],
              ),

              // Storage host and port
              const SizedBox(height: 16),
              TextField(
                controller: storageHostController,
                decoration: InputDecoration(
                  labelText: "Storage Host",
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: storagePortController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration:
                          const InputDecoration(labelText: "Storage Port"),
                    ),
                  ),
                  // button to set the port to 80
                  TextButton(
                    onPressed: () {
                      storagePortController.text = '80';
                    },
                    child: Text('80?'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.cancelButtonText.localizedOf(context)),
        ),
        TextButton(
          onPressed: () {
            viewModel.update(
              protocol: selectedProtocolNotifier.value,
              apiHost: apiHostController.text,
              apiPort: apiPortController.text,
              socketHost: apiHostController.text,
              socketPort: apiPortController.text,
              storageHost: storageHostController.text,
              storagePort: storagePortController.text,
              successNotifier: successNotifier,
            );
          },
          child: Text(localizations.saveButtonText.localizedOf(context)),
        ),
        TextButton(
          onPressed: () => {
            viewModel.resetConfigurations(),
            Navigator.of(context).pop(),
          },
          child: Text(localizations.clearButtonText.localizedOf(context)),
        ),
      ],
    );
  }
}
