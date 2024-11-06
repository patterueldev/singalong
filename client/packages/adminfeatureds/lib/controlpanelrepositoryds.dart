part of 'adminfeatureds.dart';

class ControlPanelRepositoryDS implements ControlPanelRepository {
  final SingalongAPIClient apiClient;

  ControlPanelRepositoryDS({
    required this.apiClient,
  });

  @override
  Stream<int> listenSeekDurationInMillisecondsUpdates() {
    return apiClient.listenSeekDurationInMilliseconds();
  }

  @override
  Future<void> seekToDuration(int durationInSeconds) async {
    return await apiClient.seekToDuration(durationInSeconds);
  }

  @override
  Stream<CurrentSong?> listenToCurrentSongUpdates() async* {
    await for (final apiCurrentSong in apiClient.listenCurrentSong()) {
      debugPrint("API Current Song: $apiCurrentSong");
      if (apiCurrentSong == null) {
        yield null;
        continue;
      }
      final currentSong = CurrentSong(
        id: apiCurrentSong.id,
        title: apiCurrentSong.title,
        artist: apiCurrentSong.artist,
        thumbnailURL: apiClient.resourceURL(apiCurrentSong.thumbnailPath),
        reservingUser: apiCurrentSong.reservingUser,
        durationInSeconds: apiCurrentSong.durationInSeconds,
        videoURL: apiClient.resourceURL(apiCurrentSong.videoPath),
      );
      debugPrint("Current Song: $currentSong");
      yield currentSong;
    }
  }
}
