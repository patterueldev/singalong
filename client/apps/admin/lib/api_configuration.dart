part of '_main.dart';

class APIConfiguration extends SingalongConfiguration {
  @override
  final String defaultHost;

  APIConfiguration({
    this.defaultHost = 'thursday.local',
  });

  @override
  final String persistenceStorageKey = "1234567890123456";
}
