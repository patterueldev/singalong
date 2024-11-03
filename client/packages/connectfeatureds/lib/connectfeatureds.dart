library connectfeatureds;

import 'package:connectfeature/connectfeature.dart';
import 'package:shared/shared.dart';
import 'package:provider/provider.dart';
import 'package:singalong_api_client/singalong_api_client.dart';

part 'connectrepositoryds.dart';

class ConnectFeatureDSProvider {
  final providers = MultiProvider(providers: [
    Provider<ConnectRepository>(
      create: (context) => ConnectRepositoryDS(
        client: context.read(),
        sessionManager: context.read(),
        persistenceService: context.read(),
      ),
    ),
    Provider(
      create: (context) => ConnectFeatureBuilder(
        localizations: context.read(),
        assets: context.read(),
        coordinator: context.read(),
        connectRepository: context.read(),
      ),
    ),
  ]);
}
