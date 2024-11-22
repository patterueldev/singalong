part of '../adminfeature.dart';

// TODO: To remove this because it is not used
abstract class SongBookManagerViewModel extends ChangeNotifier {
  final songListNotifier = ValueNotifier<List<SongbookItem>>([]);

  void reserveSong(SongbookItem song);
}

class DefaultSongBookManagerViewModel extends SongBookManagerViewModel {
  final ValueNotifier<List<SongbookItem>> _songListNotifier =
      ValueNotifier<List<SongbookItem>>([]);

  DefaultSongBookManagerViewModel() {
    _loadSongs();
  }

  @override
  void reserveSong(SongbookItem song) {}

  void _loadSongs() {
    _songListNotifier.value = [
      SongbookItem(
        id: "1",
        title: "Song 1",
        artist: "Artist 1",
        thumbnailURL: "https://via.placeholder.com/150",
        alreadyPlayed: false,
      ),
      SongbookItem(
        id: "2",
        title: "Song 2",
        artist: "Blur",
        thumbnailURL: "https://via.placeholder.com/150",
        alreadyPlayed: false,
      ),
      SongbookItem(
        id: "3",
        title: "Song 3",
        artist: "Artist 3",
        thumbnailURL: "https://via.placeholder.com/150",
        alreadyPlayed: false,
      ),
    ];
  }
}
