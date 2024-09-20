part of 'downloadfeature.dart';

abstract class DownloadFlowController {
  void navigateToIdentifiedSongDetailsView(BuildContext context,
      {required IdentifiedSongDetails details});
  void onDownloadSuccess(BuildContext context);
}
