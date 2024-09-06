part of 'sessionfeature.dart';

abstract class ListenToSongListUpdatesUseCase {
  Stream<List<SongItem>> execute();
}

class DefaultListenToSongListUpdatesUseCase
    implements ListenToSongListUpdatesUseCase {
  Timer? _timer;

  List<SongItem> _mockSongList = [];

  @override
  Stream<List<SongItem>> execute() {
    return Stream.periodic(const Duration(seconds: 1), (count) {
      if (_mockSongList.length >= 10) {
        _timer?.cancel();
        return _mockSongList;
      }
      _mockSongList = [
        ..._mockSongList,
        SongItem(
          title: 'Song ${_mockSongList.length + 1}',
          artist: 'Singer ${_mockSongList.length + 1}',
          imageURL: Uri.parse(
              'https://example.com/image${_mockSongList.length + 1}.jpg'),
          currentPlaying: _mockSongList.isEmpty,
          canDelete: true,
        ),
      ];
      return _mockSongList;
    });
  }
}
