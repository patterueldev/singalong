part of 'sessionfeature.dart';

abstract class SessionViewModel {
  ValueNotifier<SessionViewState> get stateNotifier;
  ValueNotifier<List<SongItem>> get songListNotifier;
}

class DefaultSessionViewModel extends SessionViewModel {
  DefaultSessionViewModel({
    List<SongItem>? songList,
  }) {
    if (songList != null) {
      songListNotifier.value = songList;
    }
  }

  @override
  ValueNotifier<SessionViewState> stateNotifier =
      ValueNotifier(const Initial());
  @override
  ValueNotifier<List<SongItem>> songListNotifier = ValueNotifier([]);
}

List<SongItem> generateSongSamples() {
  return [
    SongItem(
      title: 'Song 1',
      artist: 'Artist 1',
      imageURL: Uri.parse('https://example.com/image1.jpg'),
      currentPlaying: false,
      canDelete: true,
    ),
    SongItem(
      title: 'Song 2',
      artist: 'Artist 2',
      imageURL: Uri.parse('https://example.com/image2.jpg'),
      currentPlaying: false,
      canDelete: true,
    ),
    SongItem(
      title: 'Song 3',
      artist: 'Artist 3',
      imageURL: Uri.parse('https://example.com/image3.jpg'),
      currentPlaying: true,
      canDelete: false,
    ),
  ];
}

class SongItem {
  final String title;
  final String artist;
  final Uri? imageURL;
  final bool currentPlaying;
  final bool canDelete;

  const SongItem({
    required this.title,
    required this.artist,
    required this.imageURL,
    required this.currentPlaying,
    required this.canDelete,
  });
}

class SessionViewState {
  const SessionViewState();
}

class Initial extends SessionViewState {
  const Initial();
}

class Loading extends SessionViewState {
  const Loading();
}

class Loaded extends SessionViewState {
  const Loaded();
}

class Failure extends SessionViewState {
  final String error;
  const Failure(this.error);
}
