part of 'main.dart';

// TODO: Move these to mixins
class AppCoordinator
    implements
        ConnectNavigationCoordinator,
        SessionNavigationCoordinator,
        SongBookNavigationCoordinator,
        DownloadFlowController {
  const AppCoordinator({
    required this.connectFeatureProvider,
    required this.sessionFeatureProvider,
    required this.songBookFeatureProvider,
    required this.downloadFeatureProvider,
  });

  final ConnectFeatureProvider connectFeatureProvider;
  final SessionFeatureProvider sessionFeatureProvider;
  final SongBookFeatureProvider songBookFeatureProvider;
  final DownloadFeatureProvider downloadFeatureProvider;

  @override
  void openSongBook(BuildContext context) {
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
  void openSession(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (context) => const TemporaryScreenView(
                name: "Song Book",
              )),
    );
  }

  @override
  void backToConnectScreen(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  void openDownloadScreen(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => downloadFeatureProvider.buildIdentifyUrlView(
          context: context,
          flow: this,
          localizations: context.read(),
        ),
      ),
    );
  }

  @override
  void navigateToIdentifiedSongDetailsView(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => downloadFeatureProvider.buildSongDetailsView(
          context: context,
          localizations: context.read(),
        ),
      ),
    );
  }
}
