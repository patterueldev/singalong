part of '../connectfeature.dart';

abstract class ConnectViewModel {
  ValueNotifier<ConnectViewState> get stateNotifier;
  TextEditingController get nameController;
  TextEditingController get sessionIdController;
  void connect();
  void clear();
}

class DefaultConnectViewModel implements ConnectViewModel {
  final EstablishConnectionUseCase connectUseCase;
  DefaultConnectViewModel({
    required this.connectUseCase,
    String name = '',
    String roomId = '',
  }) {
    nameController.text = name;
    sessionIdController.text = roomId;
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
      ConnectViewStatus.connecting,
      ConnectViewStatus.connected
    ];
    if (stoppers.contains(stateNotifier.value.status)) {
      return;
    }
    stateNotifier.value = ConnectViewState.connecting();

    final name = nameController.text;
    final sessionId = sessionIdController.text;

    final result = await connectUseCase(
      EstablishConnectionParameters(
        username: name,
        roomId: sessionId,
      ),
    );
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
