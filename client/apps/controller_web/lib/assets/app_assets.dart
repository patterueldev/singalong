import 'package:connectfeature/connectfeature.dart';
import 'package:shared/shared.dart';

import '../gen/assets.gen.dart';

class DefaultAppAssets with ConnectAssetsMixin {}

mixin ConnectAssetsMixin implements ConnectAssets {
  @override
  final connectBannerImage = AssetSource(
    Assets.images.karaokeNessyou.path,
  );
}
