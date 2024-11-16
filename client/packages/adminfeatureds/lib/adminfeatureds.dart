library adminfeatureds;

import 'dart:async';

import 'package:adminfeature/adminfeature.dart';
import 'package:common/common.dart';
import 'package:commonds/commonds.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:singalong_api_client/singalong_api_client.dart';

part 'controlpanelrepositoryds.dart';
part 'rooms_repositoryds.dart';
part 'player_socket_repositoryds.dart';
part 'reservedsonglistrepositoryds.dart';

class AdminFeatureDSProvider {
  final providers = MultiProvider(providers: [
    Provider<RoomsRepository>(
      create: (context) => RoomsRepositoryDS(
        apiProvider: context.read(),
        api: context.read(),
      ),
    ),
    Provider<ControlPanelSocketRepository>(
      create: (context) => ControlPanelRepositoryDS(
        socket: context.read(),
        configuration: context.read(),
      ),
    ),
    Provider<PlayerSocketRepository>(
      create: (context) => PlayerSocketRepositoryDS(
        api: context.read(),
        socket: context.read(),
        configuration: context.read(),
      ),
    ),
    Provider<ReservedSongListSocketRepository>(
      create: (context) => ReservedSongListSocketRepositoryDS(
        socket: context.read(),
        configuration: context.read(),
      ),
    ),
    Provider.value(value: AdminFeatureUIProvider())
  ]);
}
