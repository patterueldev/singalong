part of 'main.dart';

class DefaultAppAssets with ConnectAssetsMixin implements ConnectAssetsMixin {}

mixin ConnectAssetsMixin implements ConnectAssets {
  @override
  final sessionIdLogo = AssetSource(Assets.images.meetingRoom);
}
