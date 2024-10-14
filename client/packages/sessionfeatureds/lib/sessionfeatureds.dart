library sessionfeatureds;

import 'dart:async';

import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';

class SessionFeatureDSProvider {
  final providers = MultiProvider(providers: [
    Provider<ReservedSongListRepository>(
      create: (context) => ReservedSongListRepositoryDS(),
    ),
    Provider(
      create: (context) => SessionFeatureBuilder(
        localizations: context.read(),
        coordinator: context.read(),
        reservedSongListRepository: context.read(),
      ),
    ),
  ]);
}

class ReservedSongListRepositoryDS implements ReservedSongListRepository {
  Timer? _timer;
  List<ReservedSongItem> _mockSongList = [];

  @override
  Stream<List<ReservedSongItem>> listenToSongListUpdates() {
    return Stream.periodic(const Duration(seconds: 1), (count) {
      if (_mockSongList.length >= 10) {
        _timer?.cancel();
        return _mockSongList;
      }
      _mockSongList = [
        ..._mockSongList,
        ReservedSongItem(
          id: 'id${_mockSongList.length + 1}',
          songId: 'songId${_mockSongList.length + 1}',
          title: 'Song ${_mockSongList.length + 1}',
          artist: 'Singer ${_mockSongList.length + 1}',
          imageURL: 'https://example.com/image${_mockSongList.length + 1}.jpg',
          reservingUser: 'User ${_mockSongList.length + 1}',
          currentPlaying: _mockSongList.isEmpty,
        ),
      ];
      return _mockSongList;
    });
  }
}
