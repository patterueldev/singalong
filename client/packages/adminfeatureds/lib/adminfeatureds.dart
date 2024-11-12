library adminfeatureds;

import 'dart:async';

import 'package:adminfeature/adminfeature.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:singalong_api_client/singalong_api_client.dart';

part 'controlpanelrepositoryds.dart';
part 'rooms_repositoryds.dart';

class AdminFeatureDSProvider {
  final providers = MultiProvider(providers: [
    Provider<RoomsRepository>(
      create: (context) => RoomsRepositoryDS(
        api: context.read(),
      ),
    ),
    Provider<ControlPanelSocketRepository>(
      create: (context) => ControlPanelRepositoryDS(
        socket: context.read(),
        configuration: context.read(),
      ),
    ),
    Provider(
      create: (context) => AdminFeatureUIProvider(),
    )
  ]);
}
