part of 'downloadfeature_ds.dart';

class DownloadFeatureDSProvider {
  final DownloadFeatureDSConfiguration configuration;
  DownloadFeatureDSProvider({
    required this.configuration,
  });

  late final providers = MultiProvider(providers: [
    Provider<Client>(
      create: (context) => Client(),
      dispose: (context, client) => client.close(),
    ),
    ProxyProvider<DownloadFeatureDSConfiguration, SongIdentifierRepository>(
      update: (context, configuration, previous) =>
          DefaultSongIdentifierRepository(
        client: context.read(),
        configuration: configuration,
      ),
    ),
  ]);
}
