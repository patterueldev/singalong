part of 'sessionfeature.dart';

abstract class SessionLocalizations implements GenericLocalizations {
  LocalizedString get disconnectButtonText;
  LocalizedString get cancelButtonText;
  LocalizedString get skipButtonText;
  LocalizedString get pauseButtonText;
  LocalizedString get playNextButtonText;
  LocalizedString reservedByText(String name);

  LocalizedString get skipSongTitle;
  LocalizedString get skipSongMessage;
  LocalizedString get skipSongActionText;

  LocalizedString get cancelSongTitle;
  LocalizedString get cancelSongMessage;
  LocalizedString get cancelSongActionText;
}
