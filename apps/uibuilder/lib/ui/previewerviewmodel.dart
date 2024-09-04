part of '../main.dart';

abstract class PreviewerViewModel extends ChangeNotifier {
  bool get navigateOnStartup;
  List<NavigatorItem> get navigators;
}

class DefaultPreviewerViewModel extends PreviewerViewModel {
  DefaultPreviewerViewModel({
    this.navigateOnStartup = true,
  });

  late final ConnectFeatureProvider connectFeatureProvider =
      ConnectFeatureProvider();

  @override
  final bool navigateOnStartup;

  @override
  late List<NavigatorItem> navigators = [
    NavigatorItem(
      name: "Connect",
      destination: (context) => connectFeatureProvider.buildConnectView(
        viewModel: PreviewConnectViewModel(
          name: "John Doe",
          sessionId: "123456",
        ),
      ),
    ),
  ];
}
