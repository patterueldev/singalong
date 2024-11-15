part of '../playerfeature.dart';

abstract class ReservedViewModel extends ChangeNotifier {
  final ValueNotifier<List<ReservedSongItem>> reservedViewStateNotifier =
      ValueNotifier([]);
  void setupListeners();
}

class DefaultReservedViewModel extends ReservedViewModel {
  final ReservedSongListSocketRepository reservedSongListSocketRepository;

  DefaultReservedViewModel({
    required this.reservedSongListSocketRepository,
  });

  StreamController<List<ReservedSongItem>>? reservedSongsStreamController;

  @override
  void setupListeners() {
    debugPrint('Setting up socket for reserved songs');

    reservedSongsStreamController =
        reservedSongListSocketRepository.reservedSongsStreamController;
    reservedSongsStreamController?.stream.listen((event) {
      debugPrint('Received new songs: $event');
      reservedViewStateNotifier.value = List.from(event);
    });
  }

  @override
  void dispose() {
    reservedSongsStreamController?.close();
    super.dispose();
  }
}
