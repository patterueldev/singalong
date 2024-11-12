part of 'singalong_api_client.dart';

class SingalongAPIClientProvider {
  final providers = MultiProvider(providers: [
    Provider<APISessionManager>(
      create: (context) => APISessionManager(
        configuration: context.read(),
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
