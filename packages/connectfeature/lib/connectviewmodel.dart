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

class ConnectException {
  final String message;
  ConnectException(this.message);

  String localizedOf(BuildContext context) {
    return message;
  }
}

abstract class ConnectUseCase {
  TaskEither<ConnectException, Unit> connect(String name, String sessionId);
}

class DefaultConnectUseCase implements ConnectUseCase {
  @override
  TaskEither<ConnectException, Unit> connect(String name, String sessionId) =>
      TaskEither.tryCatch(() async {
        await Future.delayed(const Duration(seconds: 2));

        throw ConnectException("Failed to connect!!!!!!");
        return unit;
      }, (e, s) {
        if (e is ConnectException) {
          return e;
        }
        return ConnectException("An unknown error occurred");
      });
}
