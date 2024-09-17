part of '../sessionfeature.dart';

class SongViewState {
  const SongViewState(this.type);

  final SongViewStateType type;

  factory SongViewState.initial() =>
      const SongViewState(SongViewStateType.initial);
  factory SongViewState.loading() =>
      const SongViewState(SongViewStateType.loading);
  factory SongViewState.loaded(SongModel song) => Loaded(song);
  factory SongViewState.failure(String error) => Failure(error);
}

class Loaded extends SongViewState {
  final SongModel song;
  const Loaded(this.song) : super(SongViewStateType.loaded);
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
