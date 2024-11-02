part of 'playerfeatureds.dart';

class CurrentSongRepositoryDS implements CurrentSongRepository {
  final SingalongAPIClient client;
  final APISessionManager sessionManager;

  CurrentSongRepositoryDS({
    required this.client,
    required this.sessionManager,
  });

  @override
  Stream<CurrentSong?> listenToCurrentSongUpdates() async* {
    await for (final apiCurrentSong in client.listenCurrentSong()) {
      debugPrint("API Current Song: $apiCurrentSong");
      if (apiCurrentSong == null) {
        yield null;
        continue;
      }
      final currentSong = CurrentSong(
        id: apiCurrentSong.id,
        title: apiCurrentSong.title,
        artist: apiCurrentSong.artist,
        thumbnailURL: client.resourceURL(apiCurrentSong.thumbnailPath),
        reservingUser: apiCurrentSong.reservingUser,
        videoURL: client.resourceURL(apiCurrentSong.videoPath),
      );
      debugPrint("Current Song: $currentSong");
      yield currentSong;
    }
  }
}
