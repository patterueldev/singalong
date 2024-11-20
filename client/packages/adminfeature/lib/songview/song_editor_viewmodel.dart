part of '../adminfeature.dart';

abstract class SongEditorViewModel extends ChangeNotifier {
  final ValueNotifier<SongViewState> stateNotifier =
      ValueNotifier(SongViewState.initial());
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> finishedSavingNotifier = ValueNotifier(false);
  final ValueNotifier<PromptModel?> promptNotifier = ValueNotifier(null);

  void loadDetails();
  void saveDetails(SongDetails song);
  void deleteSong(SongDetails song);
  void enhanceSong(SongDetails song);
}

class DefaultSongViewModel extends SongEditorViewModel {
  final SongRepository songRepository;
  DefaultSongViewModel({
    required this.songRepository,
    required this.songId,
  }) {
    loadDetails();
  }

  final String songId;

  @override
  void loadDetails() async {
    stateNotifier.value = SongViewState.loading();

    try {
      final song = await songRepository.getSongDetails(songId);
      stateNotifier.value = SongViewState.loaded(song);
    } catch (e) {
      stateNotifier.value = SongViewState.failure(e.toString());
    }
  }

  @override
  void saveDetails(SongDetails song) async {
    debugPrint('Saving song details: $song');
    isLoadingNotifier.value = true;

    try {
      await songRepository.saveSongDetails(song);
      isLoadingNotifier.value = false;
      finishedSavingNotifier.value = true;
    } catch (e) {
      isLoadingNotifier.value = false;
      promptNotifier.value = PromptModel.quick(
        title: 'Error',
        message: e.toString(),
        actionText: 'OK',
      );
    }
  }

  @override
  void deleteSong(SongDetails song) async {
    debugPrint('Deleting song: $song');
    isLoadingNotifier.value = true;

    try {
      await songRepository.deleteSongDetails(song.id);
      isLoadingNotifier.value = false;
      finishedSavingNotifier.value = true;
    } catch (e) {
      isLoadingNotifier.value = false;
      promptNotifier.value = PromptModel.quick(
        title: 'Error',
        message: e.toString(),
        actionText: 'OK',
      );
    }
  }

  @override
  void enhanceSong(SongDetails song) async {
    stateNotifier.value = SongViewState.loading();

    try {
      final enhanced = await songRepository.enhanceSongDetails(song);
      stateNotifier.value = SongViewState.loaded(enhanced);
    } catch (e) {
      stateNotifier.value = SongViewState.failure(e.toString());
    }
  }
}
