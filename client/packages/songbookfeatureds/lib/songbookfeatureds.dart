library songbookfeatureds;

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:songbookfeature/songbookfeature.dart';
import 'package:singalong_api_client/singalong_api_client.dart';

part 'songrepositoryds.dart';

class SongBookFeatureDSProvider {
  final providers = MultiProvider(providers: [
    Provider<SongRepository>(
      create: (context) => SongRepositoryDS(
        api: context.read(),
        configuration: context.read(),
      ),
    ),
    Provider(
      create: (context) => SongBookFeatureProvider(
        coordinator: context.read(),
        localizations: context.read(),
        assets: context.read(),
        songRepository: context.read(),
      ),
    ),
  ]);
}
