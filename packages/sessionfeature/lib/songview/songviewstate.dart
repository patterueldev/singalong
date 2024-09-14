part of '../sessionfeature.dart';

class SongViewState {
  const SongViewState(this.type);

  final SongViewStateType type;

  factory SongViewState.initial() =>
      const SongViewState(SongViewStateType.initial);
  factory SongViewState.loading() =>
      const SongViewState(SongViewStateType.loading);
  factory SongViewState.loaded(SongModel song) => SongLoaded(song);
  factory SongViewState.failure(String error) => SongFailure(error);
}

class SongLoaded extends SongViewState {
  final SongModel song;
  const SongLoaded(this.song) : super(SongViewStateType.loaded);
}

class SongFailure extends SongViewState {
  final String error;
  const SongFailure(this.error) : super(SongViewStateType.failure);
}

enum SongViewStateType {
  initial,
  loading,
  loaded,
  failure,
}
