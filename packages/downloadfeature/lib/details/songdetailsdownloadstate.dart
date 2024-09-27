part of '../downloadfeature.dart';

class SongDownloadState {
  final SongDownloadStatus status;

  const SongDownloadState(this.status);

  factory SongDownloadState.idle() =>
      const SongDownloadState(SongDownloadStatus.idle);
  factory SongDownloadState.loading() =>
      const SongDownloadState(SongDownloadStatus.loading);
  factory SongDownloadState.success() =>
      const SongDownloadState(SongDownloadStatus.success);
  factory SongDownloadState.failure(GenericException exception) =>
      SongDownloadFailure(exception);
}

class SongDownloadFailure extends SongDownloadState {
  final GenericException exception;

  const SongDownloadFailure(this.exception) : super(SongDownloadStatus.failure);
}

enum SongDownloadStatus {
  idle,
  loading,
  success,
  failure,
}
