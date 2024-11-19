part of '../adminfeature.dart';

class SongViewState {
  const SongViewState(this.type);

  final SongViewStateType type;

  factory SongViewState.initial() =>
      const SongViewState(SongViewStateType.initial);
  factory SongViewState.loading() =>
      const SongViewState(SongViewStateType.loading);
  factory SongViewState.loaded(SongDetails song) => Loaded(song);
  factory SongViewState.failure(String error) => Failure(error);
}

class Loaded extends SongViewState {
  late final ValueNotifier<SongDetails> songNotifier;
  final genresController = StringTagController();
  final tagsController = StringTagController();
  Loaded(
    SongDetails song,
  ) : super(SongViewStateType.loaded) {
    songNotifier = ValueNotifier(song);
  }

  void updatedWith({
    bool? isOffVocal,
    bool? videoHasLyrics,
  }) =>
      songNotifier.value = songNotifier.value.copyWith(
        isOffVocal: isOffVocal,
        videoHasLyrics: videoHasLyrics,
      );
}

class Failure extends SongViewState {
  final String error;
  const Failure(this.error) : super(SongViewStateType.failure);
}

enum SongViewStateType {
  initial,
  loading,
  loaded,
  failure,
}
