part of 'shared.dart';

class LocalizedString {
  final String Function(BuildContext context) textBuilder;
  LocalizedString(this.textBuilder);

  String localizedOf(BuildContext context) {
    return textBuilder(context);
  }

  Widget localizedTextOf(BuildContext context) {
    return Text(localizedOf(context));
  }
}
