part of '_main.dart';

class AppCoordinator extends AdminCoordinator
    implements SongBookFlowCoordinator {
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
    // TODO: implement openDownloadScreen
  }

  @override
  void openSearchDownloadablesScreen(BuildContext context, {String? query}) {
    // TODO: implement openSearchDownloadablesScreen
  }

  @override
  Future<T?> openSongDetailScreen<T>(BuildContext context, String songId) {
    return showDialog(
      context: context,
      builder: (context) => context
          .read<AdminFeatureUIProvider>()
          .buildSongbookManagerPanel(context, songId),
    );
  }
}
