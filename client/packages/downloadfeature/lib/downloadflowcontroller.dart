part of 'downloadfeature.dart';

abstract class DownloadFlowCoordinator {
  void navigateToURLIdentifierView(BuildContext context);
  void navigateToIdentifiedSongDetailsView(BuildContext context,
      {required IdentifiedSongDetails details});
  void onDownloadSuccess(BuildContext context);
  void openURL(BuildContext context, Uri url);
}
