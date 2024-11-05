library downloadfeature_ds;

import 'dart:convert';

import 'package:downloadfeature/downloadfeature.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:singalong_api_client/singalong_api_client.dart';

part 'songidentifierrepositoryds.dart';

class DownloadFeatureDSProvider {
  final providers = MultiProvider(providers: [
    Provider<SongIdentifierRepository>(
      create: (context) => DefaultSongIdentifierRepository(
        apiClient: context.read(),
      ),
    ),
    Provider(
      create: (context) => DownloadFeatureProvider(
        coordinator: context.read(),
        localizations: context.read(),
        assets: context.read(),
        songIdentifierRepository: context.read(),
      ),
    ),
  ]);
}
