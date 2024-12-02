part of 'songbookfeature.dart';

abstract class SongBookFlowCoordinator {
  void onReserved(BuildContext context);
  void openSearchDownloadablesScreen(BuildContext context, {String? query});
  void openDownloadScreen(BuildContext context, {String? url});
  Future<T?> openSongDetailScreen<T>(BuildContext context, String songId);
}
