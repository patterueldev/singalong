part of 'main.dart';

class DefaultAppAssets with ConnectAssetsMixin implements ConnectAssetsMixin {}

mixin ConnectAssetsMixin implements ConnectAssets {
  @override
  final connectBannerImage = AssetSource(
    Assets.images.karaokeNessyou.path,
  );
}
