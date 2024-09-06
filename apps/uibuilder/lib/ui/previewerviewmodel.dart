part of '../main.dart';

abstract class PreviewerViewModel extends ChangeNotifier {
  bool get navigateOnStartup;
  List<NavigatorItem> get navigators;
}

class DefaultPreviewerViewModel extends PreviewerViewModel {
  DefaultPreviewerViewModel({
    required this.connectFeatureProvider,
    required this.sessionFeatureProvider,
    this.navigateOnStartup = true,
  });

  final ConnectFeatureProvider connectFeatureProvider;
  final SessionFeatureProvider sessionFeatureProvider;

  @override
  final bool navigateOnStartup;

  @override
  late List<NavigatorItem> navigators = [
    NavigatorItem(
      name: "Session",
      destination: (context) => sessionFeatureProvider.buildSessionView(),
    ),
    NavigatorItem(
      name: "Connect",
      destination: (context) => connectFeatureProvider.buildConnectView(
        viewModel: DefaultConnectViewModel(
          name: "John Doe",
          sessionId: "123456",
        ),
      ),
    ),
  ];
}
