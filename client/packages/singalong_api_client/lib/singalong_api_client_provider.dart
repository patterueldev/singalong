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
    Provider<SingalongAPIClient>(
      create: (context) => SingalongAPIClient(
        client: context.read(),
        // socket: context.read(),
        sessionManager: context.read(),
        configuration: context.read(),
      ),
    ),
  ]);
}
