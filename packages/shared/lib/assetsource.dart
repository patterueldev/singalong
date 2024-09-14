part of 'shared.dart';

class AssetSource {
  final String path;

  const AssetSource(this.path);

  Widget toWidget() => Image.asset(path);
}
