library playerfeatureds;

import 'dart:async';

import 'package:common/common.dart';
import 'package:commonds/commonds.dart';
import 'package:flutter/foundation.dart';
import 'package:playerfeature/playerfeature.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
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
          socket: context.read(),
          configuration: context.read(),
        ),
      ),
      Provider(
        create: (context) => PlayerFeatureUIBuilder(),
      ),
    ],
  );
}
