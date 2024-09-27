part of '../sessionfeature.dart';

class SessionViewState {
  const SessionViewState(this.status);

  final SessionViewStatus status;

  factory SessionViewState.initial() =>
      const SessionViewState(SessionViewStatus.idle);
  factory SessionViewState.loading() =>
      const SessionViewState(SessionViewStatus.loading);
  factory SessionViewState.loaded() =>
      const SessionViewState(SessionViewStatus.loaded);
  factory SessionViewState.disconnected() =>
      const SessionViewState(SessionViewStatus.disconnected);
  factory SessionViewState.failure(String error) => SessionFailure(error);
}

class SessionFailure extends SessionViewState {
  final String error;
  const SessionFailure(this.error) : super(SessionViewStatus.failure);
}

enum SessionViewStatus {
  idle,
  loading,
  loaded,
  disconnected,
  failure,
}
