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
  late final SessionFeatureProvider sessionFeatureProvider =
      SessionFeatureProvider();

  @override
  final bool navigateOnStartup;

  @override
  late List<NavigatorItem> navigators = [
    NavigatorItem(
      name: "Session",
      destination: (context) => sessionFeatureProvider.buildSessionView(
        viewModel: DefaultSessionViewModel(
          songList: generateSongSamples(),
        ),
      ),
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
