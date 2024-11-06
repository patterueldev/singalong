library adminfeatureds;

import 'package:adminfeature/adminfeature.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:singalong_api_client/singalong_api_client.dart';

part 'controlpanelrepositoryds.dart';

class AdminFeatureDSProvider {
  final providers = MultiProvider(providers: [
    Provider<ControlPanelRepository>(
      create: (context) => ControlPanelRepositoryDS(
        apiClient: context.read(),
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
