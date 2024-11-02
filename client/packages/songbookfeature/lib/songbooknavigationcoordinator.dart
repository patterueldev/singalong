part of 'songbookfeature.dart';

abstract class SongBookFlowCoordinator {
  void openDownloadScreen(BuildContext context);
  void openSongDetailScreen(BuildContext context, SongItem song);
}
