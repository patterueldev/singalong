part of 'adminfeature.dart';

abstract class AdminCoordinator {
  void onSignInSuccess(BuildContext context);
  void onDisconnect(BuildContext context);
  void onRoomSelected(BuildContext context, Room room);
  void openURL(BuildContext context, Uri url);
  Future<T?> openSongDetailScreen<T>(BuildContext context, String songId);
}
