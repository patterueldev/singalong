part of 'connectfeature.dart';

class ConnectException {
  final String Function(BuildContext context) messageBuilder;
  ConnectException({required this.messageBuilder});

  String localizedOf(BuildContext context) {
    return messageBuilder(context);
  }
}
