part of 'connectfeature.dart';

abstract class ConnectLocalizations implements GenericLocalizations {
  String screenTitleText(BuildContext context);
  String connectButtonText(BuildContext context);
  String clearButtonText(BuildContext context);
  String namePlaceholderText(BuildContext context);
  String sessionIdPlaceholderText(BuildContext context);

  String connectionSuccess(BuildContext context);
  String connectionError(BuildContext context, String message);
  String invalidName(BuildContext context, String name);
  String invalidSessionId(BuildContext context, String sessionId);
}
