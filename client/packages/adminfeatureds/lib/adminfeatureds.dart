library adminfeatureds;

import 'dart:async';

import 'package:adminfeature/adminfeature.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import 'package:singalong_api_client/singalong_api_client.dart';

part 'controlpanelrepositoryds.dart';

class AdminFeatureDSProvider {
  final providers = MultiProvider(providers: [
    Provider<ControlPanelSocketRepository>(
      create: (context) => ControlPanelRepositoryDS(
        socket: context.read(),
        configuration: context.read(),
      ),
    ),
    Provider(
      create: (context) => AdminFeatureProvider(
        connectRepository: context.read(),
        controlPanelRepository: context.read(),
      ),
    )
  ]);
}
