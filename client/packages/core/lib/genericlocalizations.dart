part of 'core.dart';

abstract class GenericLocalizations {
  LocalizedString get cancelButtonText => LocalizedString(
        (context) => "Cancel",
      );
  LocalizedString get unknownError => LocalizedString(
        (context) => "An unknown error occurred",
      );
  LocalizedString unhandled(String message) => LocalizedString(
        (context) => "Unhandled error: $message",
      );
}
