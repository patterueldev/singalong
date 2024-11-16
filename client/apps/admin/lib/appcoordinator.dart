part of '_main.dart';

class AppCoordinator extends AdminCoordinator {
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
}
