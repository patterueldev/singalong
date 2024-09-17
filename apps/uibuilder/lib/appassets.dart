part of 'main.dart';

class DefaultAppAssets with ConnectAssetsMixin, SongBookAssetsMixin {}

mixin ConnectAssetsMixin implements ConnectAssets {
  @override
  final connectBannerImage = AssetSource(
    Assets.images.karaokeNessyou.path,
  );
}

mixin SongBookAssetsMixin implements SongBookAssets {
  @override
  final errorBannerImage = AssetSource(
    Assets.images.gakkariTameikiWoman.path,
  );
}
