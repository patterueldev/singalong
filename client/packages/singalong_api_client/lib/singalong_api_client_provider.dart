part of 'singalong_api_client.dart';

class SingalongAPIClientProvider {
  late final providers = buildProviders(null, null);

  MultiProvider buildProviders(String? accessToken, String? refreshToken) =>
      MultiProvider(providers: [
        Provider<APISessionManager>(
          create: (context) => APISessionManager(
            configuration: context.read(),
            accessToken: accessToken,
            refreshToken: refreshToken,
          ),
        ),
        Provider<Client>(
          create: (context) => Client(),
          dispose: (context, client) => client.close(),
        ),
        Provider<APIClient>(
          create: (context) => APIClient(
            client: context.read(),
            sessionManager: context.read(),
            configuration: context.read(),
          ),
        ),
        Provider<SingalongAPI>(
          create: (context) => SingalongAPI(
            apiClient: context.read(),
          ),
        ),
        Provider<SingalongSocket>(
          create: (context) => SingalongSocket(
            configuration: context.read(),
            sessionManager: context.read(),
          ),
        ),
      ]);
}
