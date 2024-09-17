part of 'shared.dart';

class AssetSource {
  final String path;

  const AssetSource(this.path);

  Widget image({
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    BlendMode? colorBlendMode,
    BoxFit? boxFit,
    ImageRepeat repeat = ImageRepeat.noRepeat,
  }) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      color: color,
      colorBlendMode: colorBlendMode,
      repeat: repeat,
    );
  }
}
