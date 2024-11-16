part of 'sessionfeature.dart';

abstract class SessionFlowCoordinator {
  void onSongBook(BuildContext context, {String? roomId});
  void onDisconnected(BuildContext context);
}
