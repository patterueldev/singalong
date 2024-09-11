part of 'main.dart';

class DefaultAppLocalizations
    with ConnectLocalizationsMixin, SessionLocalizationsMixin
    implements ConnectLocalizations, SessionLocalizations {}

mixin ConnectLocalizationsMixin implements ConnectLocalizations {
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
  String connectionSuccess(BuildContext context) {
    return AppLocalizations.of(context)!.connectionSuccess;
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

  @override
  String unknownError(BuildContext context) {
    return AppLocalizations.of(context)!.unknownError;
  }
}

mixin SessionLocalizationsMixin implements SessionLocalizations {
  @override
  String disconnectButtonText(BuildContext context) {
    return AppLocalizations.of(context)!.disconnectButtonText;
  }

  @override
  String cancelButtonText(BuildContext context) {
    return AppLocalizations.of(context)!.cancelButtonText;
  }

  @override
  String skipButtonText(BuildContext context) {
    return AppLocalizations.of(context)!.skipButtonText;
  }

  @override
  String pauseButtonText(BuildContext context) {
    return AppLocalizations.of(context)!.pauseButtonText;
  }

  @override
  String playNextButtonText(BuildContext context) {
    return AppLocalizations.of(context)!.playNextButtonText;
  }

  @override
  String reservedByText(BuildContext context, String name) {
    return AppLocalizations.of(context)!.reservedByText(name);
  }

  @override
  String skipSongTitle(BuildContext context) {
    return AppLocalizations.of(context)!.skipSongTitle;
  }

  @override
  String skipSongMessage(BuildContext context) {
    return AppLocalizations.of(context)!.skipSongMessage;
  }

  @override
  String skipSongActionText(BuildContext context) {
    return AppLocalizations.of(context)!.skipSongActionText;
  }

  @override
  String cancelSongTitle(BuildContext context) {
    return AppLocalizations.of(context)!.cancelSongTitle;
  }

  @override
  String cancelSongMessage(BuildContext context) {
    return AppLocalizations.of(context)!.cancelSongMessage;
  }

  @override
  String cancelSongActionText(BuildContext context) {
    return AppLocalizations.of(context)!.cancelSongActionText;
  }
}
