part of '../adminfeature.dart';

abstract class ReservedPanelViewModel extends ChangeNotifier {
  final ValueNotifier<List<ReservedSongItem>> songListNotifier =
      ValueNotifier([]);

  void dismissSong(ReservedSongItem song);
}

class DefaultReservedPanelViewModel extends ReservedPanelViewModel {
  final ReservedSongListSocketRepository reservedSongListSocketRepository;
  DefaultReservedPanelViewModel({
    required this.reservedSongListSocketRepository,
  }) {
    setup();
  }

  StreamController<List<ReservedSongItem>>? _reservedSongsStreamController;

  void setup() {
    _reservedSongsStreamController =
        reservedSongListSocketRepository.reservedSongListStreamController;
    _reservedSongsStreamController?.stream.listen((reservedSongs) {
      songListNotifier.value = List.from(reservedSongs);
    });

    reservedSongListSocketRepository.requestReservedSongList();
  }

  @override
  void dismissSong(ReservedSongItem song) {
    // TODO:
  }

  @override
  void dispose() {
    _reservedSongsStreamController?.close();
    super.dispose();
  }
}

abstract class ReservedSongListSocketRepository {
  StreamController<List<ReservedSongItem>> get reservedSongListStreamController;
  void requestReservedSongList();
}
