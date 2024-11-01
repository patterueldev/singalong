library songbookfeatureds;

import 'package:provider/provider.dart';
import 'package:songbookfeature/songbookfeature.dart';

class SongBookFeatureDSProvider {
  final providers = MultiProvider(providers: [
    Provider(
      create: (context) => SongBookFeatureProvider(
        coordinator: context.read(),
        localizations: context.read(),
        assets: context.read(),
      ),
    ),
  ]);
}
