part of 'main.dart';

// TODO: Move these to mixins
class AppCoordinator
    implements
        ConnectFlowController,
        SessionFlowController,
        SongBookNavigationCoordinator,
        DownloadFlowController {
  const AppCoordinator({
    required this.connectFeatureProvider,
    required this.sessionFeatureProvider,
    required this.songBookFeatureProvider,
    required this.downloadFeatureProvider,
  });

  final ConnectFeature connectFeatureProvider;
  final SessionFeatureProvider sessionFeatureProvider;
  final SongBookFeatureProvider songBookFeatureProvider;
  final DownloadFeatureProvider downloadFeatureProvider;

  @override
  void onSongBook(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double modalHeight = screenHeight * 0.8; // 3/4 of the screen height

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => Container(
        height: modalHeight,
        color: Colors.white,
        child: songBookFeatureProvider.buildSongBookView(
          context: context,
          coordinator: this,
          localizations: context.read(),
          assets: context.read(),
        ),
      ),
    );
  }

  @override
  void onConnected(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          settings: const RouteSettings(name: "Song Book"),
          builder: (context) => const TemporaryScreenView(name: "Song Book")),
    );
  }

  @override
  void onDisconnected(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  void openDownloadScreen(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => downloadFeatureProvider.buildIdentifyUrlView(
          context: context,
          assets: context.read(),
        ),
      ),
    );
  }

  @override
  void navigateToIdentifiedSongDetailsView(BuildContext context,
      {required IdentifiedSongDetails details}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => downloadFeatureProvider.buildSongDetailsView(
          context: context,
          identifiedSongDetails: details,
        ),
      ),
    );
  }

  @override
  void onDownloadSuccess(BuildContext context) {
    Navigator.of(context).popUntil((route) {
      return route.settings.name == "Session" ||
          route.isFirst; // fallback to root
    });
  }
}
