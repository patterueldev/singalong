part of '../main.dart';

abstract class PreviewerViewModel extends ChangeNotifier {
  int get autoNavigationIndex;
  List<NavigatorItem> get navigators;
}

class DefaultPreviewerViewModel extends PreviewerViewModel {
  DefaultPreviewerViewModel({
    required this.connectFeatureProvider,
    required this.sessionFeatureProvider,
    required this.songBookFeatureProvider,
    required this.downloadFeatureProvider,
    this.autoIndex = 0,
  });

  final ConnectFeatureProvider connectFeatureProvider;
  final SessionFeatureProvider sessionFeatureProvider;
  final SongBookFeatureProvider songBookFeatureProvider;
  final DownloadFeatureProvider downloadFeatureProvider;

  final int autoIndex;

  @override
  int get autoNavigationIndex => min(autoIndex, navigators.length - 1);

  @override
  late List<NavigatorItem> navigators = [
    NavigatorItem(
      name: "Identify Song",
      build: (context) => downloadFeatureProvider.buildIdentifyUrlView(
        context: context,
        flow: context.read(),
        localizations: context.read(),
      ),
    ),
    NavigatorItem(
      name: "Download",
      build: (context) => downloadFeatureProvider.buildSongDetailsView(
        context: context,
        localizations: context.read(),
      ),
    ),
    NavigatorItem(
      name: "Song Book",
      build: (context) => songBookFeatureProvider.buildSongBookView(
        context: context,
        coordinator: context.read(),
        localizations: context.read(),
        assets: context.read(),
      ),
    ),
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
