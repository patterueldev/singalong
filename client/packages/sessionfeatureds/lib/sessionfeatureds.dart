library sessionfeatureds;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:singalong_api_client/singalong_api_client.dart';

part 'reservedsonglistrepositoryds.dart';

class SessionFeatureDSProvider {
  final providers = MultiProvider(providers: [
    Provider<ReservedSongListRepository>(
      create: (context) => ReservedSongListRepositoryDS(
        apiClient: context.read(),
      ),
    ),
    Provider(
      create: (context) => SessionFeatureBuilder(
        localizations: context.read(),
        coordinator: context.read(),
        reservedSongListRepository: context.read(),
      ),
    ),
  ]);
}
