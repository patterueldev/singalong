part of '../playerfeature.dart';

abstract class ReservedViewModel extends ChangeNotifier {
  ValueNotifier<List<ReservedSongItem>> get reservedViewStateNotifier;
  void setupListeners();
}

class ReservedSongItem {
  final String thumbnailURL;
  final String title;
  final String artist;
  final String reservedBy;
  final bool isPlaying;

  ReservedSongItem({
    required this.thumbnailURL,
    required this.title,
    required this.artist,
    required this.reservedBy,
    required this.isPlaying,
  });
}

class DefaultReservedViewModel extends ReservedViewModel {
  final ListenToSongListUpdatesUseCase listenToSongListUpdatesUseCase;
  DefaultReservedViewModel({
    required this.listenToSongListUpdatesUseCase,
  });

  StreamSubscription? reservedSongsListener;

  @override
  final ValueNotifier<List<ReservedSongItem>> reservedViewStateNotifier =
      ValueNotifier([]);

  @override
  void setupListeners() {
    debugPrint('Setting up socket for reserved songs');
    reservedSongsListener?.cancel();
    reservedSongsListener = listenToSongListUpdatesUseCase().listen((songs) {
      debugPrint('Received new songs: $songs');
      reservedViewStateNotifier.value = List.from(songs);
    });
  }

  @override
  void dispose() {
    reservedSongsListener?.cancel();
    super.dispose();
  }
}
