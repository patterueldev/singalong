part of '../sessionfeature.dart';

class SessionViewState {
  const SessionViewState(this.type);

  final SessionViewStateType type;

  factory SessionViewState.initial() =>
      const SessionViewState(SessionViewStateType.initial);
  factory SessionViewState.loading() =>
      const SessionViewState(SessionViewStateType.loading);
  factory SessionViewState.loaded() =>
      const SessionViewState(SessionViewStateType.loaded);
  factory SessionViewState.disconnected() =>
      const SessionViewState(SessionViewStateType.disconnected);
  factory SessionViewState.failure(String error) => Failure(error);
}

class Failure extends SessionViewState {
  final String error;
  const Failure(this.error) : super(SessionViewStateType.failure);
}

enum SessionViewStateType {
  initial,
  loading,
  loaded,
  disconnected,
  failure,
}
