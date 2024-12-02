part of '_main.dart';

class AppCoordinator extends AdminCoordinator
    implements SongBookFlowCoordinator, DownloadFlowCoordinator {
  @override
  void onSignInSuccess(BuildContext context) {
    debugPrint('onSignInSuccess');
    context.read<AdminAppViewModel>().checkAuthentication();
  }

  @override
  void onDisconnect(BuildContext context) {
    debugPrint('onDisconnect');
    context.read<AdminAppViewModel>().checkAuthentication();
  }

  @override
  void onRoomSelected(BuildContext context, Room room) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider<MasterViewModel>(
          create: (context) => DefaultMasterViewModel(room: room),
          child: const MasterView(),
        ),
        settings: RouteSettings(name: '/master'),
      ),
    );
  }

  @override
  void openURL(BuildContext context, Uri url) {
    debugPrint("Launching URL: $url");
    canLaunchUrl(url).then((canLaunch) async {
      if (!canLaunch) {
        debugPrint("Cannot launch URL: $url");
        return;
      }
      await launchUrl(url, mode: LaunchMode.externalApplication);
    });
  }

  @override
  void openDownloadScreen(BuildContext context, {String? url}) {
    DownloadFeatureProvider downloadFeatureProvider = context.read();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => downloadFeatureProvider.buildIdentifyUrlView(
            context: context, url: url),
      ),
    );
  }

  @override
  void openSearchDownloadablesScreen(BuildContext context, {String? query}) {
    DownloadFeatureProvider downloadFeatureProvider = context.read();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            downloadFeatureProvider.buildSearchDownloadableView(query: query),
      ),
    );
  }

  @override
  Future<T?> openSongDetailScreen<T>(BuildContext context, String songId) {
    return showDialog(
      context: context,
      builder: (context) => context
          .read<AdminFeatureUIProvider>()
          .buildSongEditorPanel(context, songId),
    );
  }

  @override
  void onReserved(BuildContext context) {
    // TODO: implement onReserved
    // nothing to do in admin
  }

  @override
  void navigateToIdentifiedSongDetailsView(BuildContext context,
      {required IdentifiedSongDetails details}) {
    DownloadFeatureProvider downloadFeatureProvider = context.read();
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
  void navigateToURLIdentifierView(BuildContext context) {
    openDownloadScreen(context);
  }

  @override
  void onDownloadSuccess(BuildContext context) {
    Navigator.popUntil(context, (route) {
      debugPrint('Checking route: ${route.settings.name}');
      return route.settings.name == '/master';
    });
  }
}
