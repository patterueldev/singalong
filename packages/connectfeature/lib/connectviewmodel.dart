part of 'connectfeature.dart';

abstract class ConnectViewModel {
  ValueNotifier<ConnectViewState> get stateNotifier;
  TextEditingController get nameController;
  TextEditingController get sessionIdController;
  void connect();
  void clear();
}

class DefaultConnectViewModel implements ConnectViewModel {
  final ConnectUseCase connectUseCase;
  DefaultConnectViewModel({
    required this.connectUseCase,
    String name = '',
    String sessionId = '',
  }) {
    nameController.text = name;
    sessionIdController.text = sessionId;
  }
  @override
  final TextEditingController nameController = TextEditingController();
  @override
  final TextEditingController sessionIdController = TextEditingController();

  @override
  final ValueNotifier<ConnectViewState> stateNotifier =
      ValueNotifier(ConnectViewState.initial());

  bool didShowError = false;
  @override
  void connect() async {
    const stoppers = [
      ConnectViewStateType.connecting,
      ConnectViewStateType.connected
    ];
    if (stoppers.contains(stateNotifier.value.type)) {
      return;
    }
    stateNotifier.value = ConnectViewState.connecting();

    final name = nameController.text;
    final sessionId = sessionIdController.text;

    final result = await connectUseCase.connect(name, sessionId).run();
    result.fold(
      (e) {
        stateNotifier.value = ConnectViewState.failure(e);
      },
      (_) {
        stateNotifier.value = ConnectViewState.connected();
      },
    );
  }

  @override
  void clear() {
    nameController.clear();
    sessionIdController.clear();
  }
}

abstract class GenericLocalizations {
  String unknownError(BuildContext context);
}

class ConnectException {
  final String Function(BuildContext context) messageBuilder;
  ConnectException({required this.messageBuilder});

  String localizedOf(BuildContext context) {
    return messageBuilder(context);
  }
}
