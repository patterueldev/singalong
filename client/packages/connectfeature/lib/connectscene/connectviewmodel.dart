part of '../connectfeature.dart';

abstract class ConnectViewModel extends ChangeNotifier {
  ValueNotifier<ConnectViewState> get stateNotifier;
  TextEditingController get nameController;
  TextEditingController get sessionIdController;
  void load();
  void connect();
  void clear();
}

class DefaultConnectViewModel extends ConnectViewModel {
  final ConnectRepository connectRepository;
  final PersistenceRepository persistenceService;

  DefaultConnectViewModel({
    required this.connectRepository,
    required this.persistenceService,
    this.name,
    this.roomId,
  });

  late final EstablishConnectionUseCase connectUseCase =
      EstablishConnectionUseCase(
    connectRepository: connectRepository,
    persistenceRepository: persistenceService,
  );

  @override
  final TextEditingController nameController = TextEditingController();
  @override
  final TextEditingController sessionIdController = TextEditingController();

  @override
  final ValueNotifier<ConnectViewState> stateNotifier =
      ValueNotifier(ConnectViewState.initial());

  String? name;
  String? roomId;

  bool didShowError = false;

  @override
  void load() async {
    stateNotifier.value = ConnectViewState.connecting();
    name = name ?? await persistenceService.getUsername();
    roomId = roomId ?? await persistenceService.getRoomId();
    nameController.text = name ?? nameController.text;
    sessionIdController.text = roomId ?? sessionIdController.text;
    debugPrint('name: $name, roomId: $roomId');
    stateNotifier.value = ConnectViewState.initial();
  }

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
