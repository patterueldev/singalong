part of 'songbookfeature.dart';

abstract class SongBookFlowCoordinator {
  void openDownloadScreen(BuildContext context, {String? url});
  void openSongDetailScreen(BuildContext context, SongItem song);
}
