part of 'connectfeature.dart';

abstract class ConnectLocalizations implements GenericLocalizations {
  LocalizedString get connectScreenTitleText;
  LocalizedString get connectButtonText;
  LocalizedString get clearButtonText;
  LocalizedString get namePlaceholderText;
  LocalizedString get sessionIdPlaceholderText;

  LocalizedString get connectionSuccess;
  LocalizedString get emptyName;
  LocalizedString get emptySessionId;
  LocalizedString invalidName(String name);
  LocalizedString invalidSessionId(String sessionId);

  LocalizedString get editServerHostDialogTitle => LocalizedString(
        (context) => "Customize Server Host",
      );
  LocalizedString get serverHostPlaceholderText => LocalizedString(
        (context) => "API Host",
      );
  LocalizedString get saveButtonText => LocalizedString(
        (context) => "Save",
      );
}
