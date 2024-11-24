part of '../connectfeature.dart';

abstract class ConnectViewModel extends ChangeNotifier {
  final ValueNotifier<ConnectViewState> stateNotifier =
      ValueNotifier(ConnectViewState.initial());
  final TextEditingController nameController = TextEditingController();
  final TextEditingController sessionIdController = TextEditingController();

  ValueNotifier<SingalongConfiguration> get singalongConfigurationNotifier;

  void load();
  void connect();
  void clear();

  void resetConfigurations();
  void update({
    required String protocol,
    required String apiHost,
    required String apiPort,
    required String socketHost,
    required String socketPort,
    required String storageHost,
    required String storagePort,
    required ValueNotifier<bool> successNotifier,
  });
}

class DefaultConnectViewModel extends ConnectViewModel {
  final ConnectRepository connectRepository;
  final PersistenceRepository persistenceRepository;

  DefaultConnectViewModel({
    required this.connectRepository,
    required this.persistenceRepository,
    required SingalongConfiguration singalongConfiguration,
    this.name,
    this.roomId,
  }) : singalongConfigurationNotifier = ValueNotifier(singalongConfiguration);

  late final EstablishConnectionUseCase connectUseCase =
      EstablishConnectionUseCase(
    connectRepository: connectRepository,
    persistenceRepository: persistenceRepository,
  );

  @override
  final ValueNotifier<SingalongConfiguration> singalongConfigurationNotifier;

  String? name;
  String? roomId;

  bool didShowError = false;

  @override
  void load() async {
    stateNotifier.value = ConnectViewState.connecting();
    name = name ?? await persistenceRepository.getUsername();
    roomId = roomId ?? await persistenceRepository.getRoomId();
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
  void resetConfigurations() {
    stateNotifier.value = ConnectViewState.connecting();
    persistenceRepository.clear(PersistenceKey.customApiProtocol);
    persistenceRepository.clear(PersistenceKey.customApiHost);
    persistenceRepository.clear(PersistenceKey.customApiPort);
    persistenceRepository.clear(PersistenceKey.customSocketHost);
    persistenceRepository.clear(PersistenceKey.customSocketPort);
    persistenceRepository.clear(PersistenceKey.customStorageHost);
    persistenceRepository.clear(PersistenceKey.customStoragePort);
    singalongConfigurationNotifier.value.customProtocol = null;
    singalongConfigurationNotifier.value.customApiHost = null;
    singalongConfigurationNotifier.value.customApiPort = null;
    singalongConfigurationNotifier.value.customSocketHost = null;
    singalongConfigurationNotifier.value.customSocketPort = null;
    singalongConfigurationNotifier.value.customStorageHost = null;
    singalongConfigurationNotifier.value.customStoragePort = null;
    singalongConfigurationNotifier.notifyListeners();
    stateNotifier.value = ConnectViewState.initial();
  }

  Future<void> _updateConfiguration(Future<void> Function() setter) async {
    stateNotifier.value = ConnectViewState.connecting();
    await setter();
    singalongConfigurationNotifier.notifyListeners();
    stateNotifier.value = ConnectViewState.initial();
  }

  Future<void> _updatePortConfiguration(
      String port, Future<void> Function(int) setter) async {
    stateNotifier.value = ConnectViewState.connecting();
    int? portInt;
    try {
      portInt = int.parse(port);
    } catch (e) {
      stateNotifier.value = ConnectViewState.failure(
        const CustomException("Invalid port number"),
      );
      return;
    }
    await setter(portInt);
    singalongConfigurationNotifier.notifyListeners();
    stateNotifier.value = ConnectViewState.initial();
  }

  void update({
    required String protocol,
    required String apiHost,
    required String apiPort,
    required String socketHost,
    required String socketPort,
    required String storageHost,
    required String storagePort,
    required ValueNotifier<bool> successNotifier,
  }) async {
    try {
      await _updateConfiguration(() async {
        await persistenceRepository.saveString(
            PersistenceKey.customApiProtocol, protocol);
        await persistenceRepository.saveString(
            PersistenceKey.customApiHost, apiHost);
        await persistenceRepository.saveString(
            PersistenceKey.customSocketHost, socketHost);
        await persistenceRepository.saveString(
            PersistenceKey.customStorageHost, storageHost);
        singalongConfigurationNotifier.value.customProtocol = protocol;
        singalongConfigurationNotifier.value.customApiHost = apiHost;
        singalongConfigurationNotifier.value.customSocketHost = socketHost;
        singalongConfigurationNotifier.value.customStorageHost = storageHost;
      });

      await _updatePortConfiguration(apiPort, (int port) async {
        await persistenceRepository.saveInt(PersistenceKey.customApiPort, port);
        singalongConfigurationNotifier.value.customApiPort = port;
      });

      await _updatePortConfiguration(socketPort, (int port) async {
        await persistenceRepository.saveInt(
            PersistenceKey.customSocketPort, port);
        singalongConfigurationNotifier.value.customSocketPort = port;
      });

      await _updatePortConfiguration(storagePort, (int port) async {
        await persistenceRepository.saveInt(
            PersistenceKey.customStoragePort, port);
        singalongConfigurationNotifier.value.customStoragePort = port;
      });

      successNotifier.value = true;
    } catch (e) {
      debugPrint('error: $e');
      successNotifier.value = false;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    sessionIdController.dispose();
    super.dispose();
  }
}
