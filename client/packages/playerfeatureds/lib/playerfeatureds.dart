library playerfeatureds;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:playerfeature/playerfeature.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import 'package:singalong_api_client/singalong_api_client.dart';

part 'playersocketrepositoryds.dart';
part 'reservedsonglistsocketrepositoryds.dart';

class PlayerFeatureDSProvider {
  final providers = MultiProvider(
    providers: [
      Provider<PlayerSocketRepository>(
        create: (context) => PlayerSocketRepositoryDS(
          socket: context.read(),
          configuration: context.read(),
        ),
      ),
      Provider<ReservedSongListSocketRepository>(
        create: (context) => ReservedSongListRepositoryDS(
          apiClient: context.read(),
          configuration: context.read(),
        ),
      ),
      Provider(
        create: (context) => PlayerFeatureUIBuilder(),
      ),
    ],
  );
}
