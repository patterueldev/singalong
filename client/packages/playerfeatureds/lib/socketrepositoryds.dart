part of 'playerfeatureds.dart';

class SocketRepositoryDS implements SocketRepository {
  final SingalongAPIClient client;

  SocketRepositoryDS({
    required this.client,
  });

  @override
  Future<void> updateSeekDuration(int durationInMilliseconds) async {
    await client.updateSeekDuration(durationInMilliseconds);
  }

  @override
  Stream<int> listenSeekUpdatesInSeconds() {
    return client.listenSeekUpdatesInSeconds();
  }
}
