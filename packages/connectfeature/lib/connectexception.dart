part of 'connectfeature.dart';

class ConnectException {
  final LocalizedString localizedString;
  ConnectException(this.localizedString);

  String localizedOf(BuildContext context) {
    return localizedString.localizedOf(context);
  }
}
