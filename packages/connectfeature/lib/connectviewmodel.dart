part of 'connectfeature.dart';

abstract class ConnectViewModel {
  ValueNotifier<ConnectViewState> get stateNotifier;
  TextEditingController get nameController;
  TextEditingController get sessionIdController;
  void connect();
  void clear();
}

class DefaultConnectViewModel implements ConnectViewModel {
  DefaultConnectViewModel({
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
    stateNotifier.value = ConnectViewState.connecting();

    await Future.delayed(const Duration(seconds: 2));

    stateNotifier.value = ConnectViewState.failure("Failed to connect");
  }

  @override
  void clear() {
    nameController.clear();
    sessionIdController.clear();
  }
}
