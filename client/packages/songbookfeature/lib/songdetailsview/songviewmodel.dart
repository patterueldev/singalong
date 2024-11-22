part of '../songbookfeature.dart';

abstract class SongViewModel extends ChangeNotifier {
  final ValueNotifier<SongViewState> stateNotifier =
      ValueNotifier(SongViewState.initial());
}

class DefaultSongViewModel extends SongViewModel {
  final SongRepository songRepository;
  final String songId;

  DefaultSongViewModel({
    required this.songRepository,
    required this.songId,
  }) {
    loadDetails();
  }

  void loadDetails() async {
    stateNotifier.value = SongViewState.loading();

    try {
      final song = await songRepository.getSongDetails(songId);
      stateNotifier.value = SongViewState.loaded(song);
    } catch (e) {
      stateNotifier.value = SongViewState.failure(e.toString());
    }
  }
}
