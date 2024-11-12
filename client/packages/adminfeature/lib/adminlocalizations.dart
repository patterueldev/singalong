part of 'adminfeature.dart';

abstract class AdminLocalizations extends GenericLocalizations {
  LocalizedString get clearButtonText => LocalizedString(
        (context) => "Clear",
      );

  LocalizedString get editServerHostDialogTitle => LocalizedString(
        (context) => "Customize Server Host",
      );
  LocalizedString get serverHostPlaceholderText => LocalizedString(
        (context) => "Enter the server host",
      );
  LocalizedString get saveButtonText => LocalizedString(
        (context) => "Save",
      );
}
