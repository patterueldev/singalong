import 'package:connectfeature/connectfeature.dart';
import 'package:downloadfeature/downloadfeature.dart';
import 'package:core/core.dart';
import 'package:songbookfeature/songbookfeature.dart';

import '../gen/assets.gen.dart';

class DefaultAppAssets
    with ConnectAssetsMixin, SongBookAssetsMixin, DownloadAssetsMixin {}

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

mixin DownloadAssetsMixin implements DownloadAssets {
  @override
  final identifySongBannerImage = AssetSource(
    Assets.images.magnifier4Woman.path,
  );
}
