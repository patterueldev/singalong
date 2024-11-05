part of 'downloadfeature.dart';

abstract class DownloadFlowCoordinator {
  void navigateToURLIdentifierView(BuildContext context);
  void navigateToIdentifiedSongDetailsView(BuildContext context,
      {required IdentifiedSongDetails details});
  void onDownloadSuccess(BuildContext context);
  void previewDownloadable(BuildContext context, DownloadableItem downloadable);
}
