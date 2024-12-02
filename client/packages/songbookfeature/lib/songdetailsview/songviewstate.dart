part of '../songbookfeature.dart';

class SongViewState {
  const SongViewState(this.type);

  final SongViewStateType type;

  factory SongViewState.initial() =>
      const SongViewState(SongViewStateType.initial);
  factory SongViewState.loading() =>
      const SongViewState(SongViewStateType.loading);
  factory SongViewState.loaded(SongDetails song) => SongDetailsLoaded(song);
  factory SongViewState.failure(String error) => SongDetailsFailure(error);
}

class SongDetailsLoaded extends SongViewState {
  final SongDetails song;
  const SongDetailsLoaded(this.song) : super(SongViewStateType.loaded);
}

class SongDetailsFailure extends SongViewState {
  final String error;
  const SongDetailsFailure(this.error) : super(SongViewStateType.failure);
}

enum SongViewStateType {
  initial,
  loading,
  loaded,
  failure,
}
