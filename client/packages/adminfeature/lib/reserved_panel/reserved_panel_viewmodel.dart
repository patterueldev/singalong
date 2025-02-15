part of '../adminfeature.dart';

abstract class ReservedPanelViewModel extends ChangeNotifier {
  final ValueNotifier<List<ReservedSongItem>> songListNotifier =
      ValueNotifier([]);

  void nextSong();
  void cancelReservation(String songId);
  void moveUp(String songId);
}

class DefaultReservedPanelViewModel extends ReservedPanelViewModel {
  final ReservedSongListSocketRepository reservedSongListSocketRepository;
  final ControlPanelSocketRepository controlPanelRepository;
  DefaultReservedPanelViewModel({
    required this.reservedSongListSocketRepository,
    required this.controlPanelRepository,
  }) {
    setup();
  }

  StreamController<List<ReservedSongItem>>? _reservedSongsStreamController;
  int nextOrder = -1;

  void setup() {
    _reservedSongsStreamController =
        reservedSongListSocketRepository.reservedSongListStreamController;
    _reservedSongsStreamController?.stream.listen((reservedSongs) {
      songListNotifier.value = List.from(reservedSongs);
      try {
        nextOrder = reservedSongs.firstWhere((reserved) {
              return reserved.currentPlaying;
            }).order +
            1;
      } catch (e) {
        debugPrint("No current playing song");
        nextOrder = -1;
      }
    });

    reservedSongListSocketRepository.requestReservedSongList();
  }

  @override
  void nextSong() {
    controlPanelRepository.skipSong(completed: false);
  }

  @override
  void cancelReservation(String reservedSongId) {
    controlPanelRepository.cancelReservation(reservedSongId);
  }

  @override
  void moveUp(String reservedSongId) {
    if (nextOrder == -1) {
      return;
    }
    controlPanelRepository.moveReservedSongOrder(reservedSongId, nextOrder);
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
