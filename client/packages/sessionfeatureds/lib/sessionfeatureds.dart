library sessionfeatureds;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:core/core.dart';
import 'package:singalong_api_client/singalong_api_client.dart';

part 'reservedsonglistsocketrepositoryds.dart';

class SessionFeatureDSProvider {
  final providers = MultiProvider(providers: [
    Provider<ReservedSongListSocketRepository>(
      create: (context) => ReservedSongListSocketRepositoryDS(
        socket: context.read(),
        configuration: context.read(),
      ),
    ),
    Provider(
      create: (context) => SessionFeatureUIBuilder(),
    ),
  ]);
}
