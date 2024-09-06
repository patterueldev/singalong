part of 'sessionfeature.dart';

abstract class SessionViewModel {
  ValueNotifier<SessionViewState> get stateNotifier;
  ValueNotifier<List<SongItem>> get songListNotifier;

  void setupSession();
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

  Timer? _timer;

  @override
  void setupSession() async {
    // this class will essentially "prepare" the session
    // maybe processing some stuff at first
    // then setup an active observer to listen to changes for the song list
    stateNotifier.value = const Loading();
    await Future.delayed(const Duration(seconds: 2));
    // if there's an error, we can throw an exception; use Failure state instead of Loading
    stateNotifier.value = const Loaded();

    // then start listening to changes
    startListening();
  }

  // mock observer; maybe add songs every 5 seconds
  void startListening() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (songListNotifier.value.length >= 10) {
        timer.cancel();
        return;
      }
      songListNotifier.value = [
        ...songListNotifier.value,
        SongItem(
          title: 'Song ${songListNotifier.value.length + 1}',
          artist: 'Artist ${songListNotifier.value.length + 1}',
          imageURL: Uri.parse(
              'https://example.com/image${songListNotifier.value.length + 1}.jpg'),
          currentPlaying: songListNotifier.value.isEmpty,
          canDelete: true,
        ),
      ];
    });
  }
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
