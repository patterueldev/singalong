part of 'connectfeature.dart';

abstract class ConnectViewModel {
  ValueNotifier<bool> get loadingNotifier;
  ValueNotifier<String?> get errorNotifier;
  TextEditingController get nameController;
  TextEditingController get sessionIdController;
  void connect();
  void clear();
  void dismissError();
}

class PreviewConnectViewModel implements ConnectViewModel {
  PreviewConnectViewModel({
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
  final ValueNotifier<bool> loadingNotifier = ValueNotifier(false);

  @override
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  bool didShowError = false;
  @override
  void connect() async {
    loadingNotifier.value = true;
    errorNotifier.value = null;

    await Future.delayed(const Duration(seconds: 2));

    errorNotifier.value = 'Failed to connect';
    loadingNotifier.value = false;
  }

  @override
  void clear() {
    nameController.clear();
    sessionIdController.clear();
  }

  @override
  void dismissError() {
    errorNotifier.value = null;
  }
}

class DefaultConnectViewModel implements ConnectViewModel {
  DefaultConnectViewModel();

  @override
  final TextEditingController nameController = TextEditingController();
  @override
  final TextEditingController sessionIdController = TextEditingController();

  @override
  final ValueNotifier<bool> loadingNotifier = ValueNotifier(false);

  @override
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  @override
  void connect() async {
    loadingNotifier.value = true;

    await Future.delayed(const Duration(seconds: 2));

    loadingNotifier.value = false;
  }

  @override
  void clear() {
    nameController.clear();
    sessionIdController.clear();
  }

  @override
  void dismissError() {
    errorNotifier.value = null;
  }
}
