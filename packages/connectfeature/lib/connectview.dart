part of 'connectfeature.dart';

class ConnectView extends StatefulWidget {
  const ConnectView({
    super.key,
    required this.viewModel,
  });

  final ConnectViewModel viewModel;

  @override
  State<ConnectView> createState() => _ConnectViewState();
}

class _ConnectViewState extends State<ConnectView> {
  ConnectViewModel get viewModel => widget.viewModel;
  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text('Connect'),
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            ),
            body: _buildBody(context, viewModel),
          ),
          ValueListenableBuilder(
            valueListenable: viewModel.loadingNotifier,
            builder: (context, isLoading, child) => isLoading
                ? Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
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
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: viewModel.sessionIdController,
                decoration: const InputDecoration(
                  labelText: 'Session ID',
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
                          onPressed: () => viewModel.connect(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Connect'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: buttonWidth,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => viewModel.clear(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Theme.of(context).colorScheme.secondary),
                            foregroundColor:
                                Theme.of(context).colorScheme.secondary,
                          ),
                          child: const Text('Clear'),
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
