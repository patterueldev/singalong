part of '../connectfeature.dart';

abstract class ConnectViewModel extends ChangeNotifier {
  final ValueNotifier<ConnectViewState> stateNotifier =
      ValueNotifier(ConnectViewState.initial());
  final TextEditingController nameController = TextEditingController();
  final TextEditingController sessionIdController = TextEditingController();

  // SingalongConfiguration get singalongConfiguration;
  ValueNotifier<SingalongConfiguration> get singalongConfigurationNotifier;

  void load();
  void connect();
  void clear();

  void updateServerHost(String host);
  void resetServerHost();
}

class DefaultConnectViewModel extends ConnectViewModel {
  final ConnectRepository connectRepository;
  final PersistenceRepository persistenceService;
  @override
  // final SingalongConfiguration singalongConfiguration;
  late final ValueNotifier<SingalongConfiguration>
      singalongConfigurationNotifier;

  DefaultConnectViewModel({
    required this.connectRepository,
    required this.persistenceService,
    required SingalongConfiguration singalongConfiguration,
    this.name,
    this.roomId,
  }) : singalongConfigurationNotifier = ValueNotifier(singalongConfiguration);

  late final EstablishConnectionUseCase connectUseCase =
      EstablishConnectionUseCase(
    connectRepository: connectRepository,
    persistenceRepository: persistenceService,
  );

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
    notifyListeners();
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
        debugPrint('fold error: $e');
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

  @override
  void updateServerHost(String host) async {
    stateNotifier.value = ConnectViewState.connecting();
    persistenceService.saveCustomHost(host);
    singalongConfigurationNotifier.value.customHost = host;
    singalongConfigurationNotifier.notifyListeners();
    stateNotifier.value = ConnectViewState.initial();
  }

  @override
  void resetServerHost() async {
    stateNotifier.value = ConnectViewState.connecting();
    await persistenceService.clearCustomHost();
    singalongConfigurationNotifier.value.customHost = null;
    singalongConfigurationNotifier.notifyListeners();
    stateNotifier.value = ConnectViewState.initial();
  }
}
