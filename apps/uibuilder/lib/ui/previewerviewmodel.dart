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
      build: (context) => sessionFeatureProvider.buildSessionView(
        context: context,
        coordinator: context.read(),
        localizations: context.read(),
      ),
    ),
    NavigatorItem(
      name: "Connect",
      build: (context) => connectFeatureProvider.buildConnectView(
        context: context,
        coordinator: context.read(),
        localizations: context.read(),
        assets: context.read(),
        name: "John Doe",
        sessionId: "123456",
      ),
    ),
  ];
}
