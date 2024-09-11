part of 'sessionfeature.dart';

abstract class SessionLocalizations implements GenericLocalizations {
  String disconnectButtonText(BuildContext context);
  String cancelButtonText(BuildContext context);
  String skipButtonText(BuildContext context);
  String pauseButtonText(BuildContext context);
  String playNextButtonText(BuildContext context);
  String reservedByText(BuildContext context, String name);

  String skipSongTitle(BuildContext context);
  String skipSongMessage(BuildContext context);
  String skipSongActionText(BuildContext context);

  String cancelSongTitle(BuildContext context);
  String cancelSongMessage(BuildContext context);
  String cancelSongActionText(BuildContext context);
}
