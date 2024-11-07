part of 'core.dart';

class LocalizedString {
  final String Function(BuildContext context) textBuilder;
  LocalizedString(this.textBuilder);

  String localizedOf(BuildContext context) {
    return textBuilder(context);
  }

  Widget localizedTextOf(
    BuildContext context, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    bool? softWrap,
  }) {
    return Text(
      localizedOf(context),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
