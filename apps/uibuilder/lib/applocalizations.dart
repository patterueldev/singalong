part of 'main.dart';

class DefaultAppLocalizable implements ConnectLocalizable {
  @override
  String screenTitleText(BuildContext context) {
    return AppLocalizations.of(context)!.screenTitleText;
  }

  @override
  String connectButtonText(BuildContext context) {
    return AppLocalizations.of(context)!.connectButtonText;
  }

  @override
  String clearButtonText(BuildContext context) {
    return AppLocalizations.of(context)!.clearButtonText;
  }

  @override
  String namePlaceholderText(BuildContext context) {
    return AppLocalizations.of(context)!.namePlaceholderText;
  }

  @override
  String sessionIdPlaceholderText(BuildContext context) {
    return AppLocalizations.of(context)!.sessionIdPlaceholderText;
  }

  @override
  String unknownError(BuildContext context) {
    return AppLocalizations.of(context)!.unknownError;
  }

  @override
  String connectionError(BuildContext context, String message) {
    return AppLocalizations.of(context)!.connectionError(message);
  }

  @override
  String invalidName(BuildContext context, String name) {
    return AppLocalizations.of(context)!.invalidName(name);
  }

  @override
  String invalidSessionId(BuildContext context, String sessionId) {
    return AppLocalizations.of(context)!.invalidSessionId(sessionId);
  }
}
