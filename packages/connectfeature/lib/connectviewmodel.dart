part of 'connectfeature.dart';

abstract class ConnectViewModel {
  ValueNotifier<bool> get loadingNotifier;
  TextEditingController get nameController;
  TextEditingController get sessionIdController;
  void connect(BuildContext context);
  void clear(BuildContext context);
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
  void connect(BuildContext context) async {
    loadingNotifier.value = true;

    await Future.delayed(const Duration(seconds: 2));

    loadingNotifier.value = false;
  }

  @override
  void clear(BuildContext context) {
    nameController.clear();
    sessionIdController.clear();
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
  void connect(BuildContext context) async {
    loadingNotifier.value = true;

    await Future.delayed(const Duration(seconds: 2));

    loadingNotifier.value = false;
  }

  @override
  void clear(BuildContext context) {
    nameController.clear();
    sessionIdController.clear();
  }
}
