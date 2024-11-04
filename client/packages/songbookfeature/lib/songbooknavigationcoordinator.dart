part of 'songbookfeature.dart';

abstract class SongBookFlowCoordinator {
  void openSearchDownloadablesScreen(BuildContext context, {String? query});
  void openDownloadScreen(BuildContext context, {String? url});
  void openSongDetailScreen(BuildContext context, SongItem song);
}
