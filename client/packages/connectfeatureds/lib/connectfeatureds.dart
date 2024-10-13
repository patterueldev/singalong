library connectfeatureds;

import 'package:connectfeature/connectfeature.dart';
import 'package:provider/provider.dart';
import 'package:singalong_api_client/singalong_api_client.dart';

class ConnectFeatureDSProvider {
  final providers = MultiProvider(providers: [
    Provider<ConnectRepository>(
      create: (context) => ConnectRepositoryDS(
        client: context.read(),
      ),
    ),
    Provider(
      create: (context) => ConnectFeature(
        localizations: context.read(),
        assets: context.read(),
        coordinator: context.read(),
        connectRepository: context.read(),
      ),
    ),
  ]);
}

class ConnectRepositoryDS implements ConnectRepository {
  final SingalongAPIClient client;

  ConnectRepositoryDS({required this.client});

  @override
  Future<ConnectResponse> connect(ConnectParameters parameters) async {
    final result = await client.connect(parameters.toAPI());
    return result.fromAPI();
  }
}

extension ConnectParametersMapper on ConnectParameters {
  APIConnectParameters toAPI() {
    return APIConnectParameters(
      username: username,
      roomId: roomId,
      clientType: clientType,
    );
  }
}

extension APIConnectResponseMapper on APIConnectResponseData {
  ConnectResponse fromAPI() {
    return ConnectResponse(
      requiresUserPasscode: requiresUserPasscode,
      requiresRoomPasscode: requiresRoomPasscode,
      accessToken: accessToken,
    );
  }
}
