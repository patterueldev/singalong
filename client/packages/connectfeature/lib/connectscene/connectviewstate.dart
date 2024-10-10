part of '../connectfeature.dart';

class ConnectViewState {
  const ConnectViewState(this.status);

  final ConnectViewStatus status;

  factory ConnectViewState.initial() =>
      const ConnectViewState(ConnectViewStatus.initial);
  factory ConnectViewState.connecting() =>
      const ConnectViewState(ConnectViewStatus.connecting);
  factory ConnectViewState.connected() =>
      const ConnectViewState(ConnectViewStatus.connected);
  factory ConnectViewState.failure(GenericException error) => Failure(error);
}

class Failure extends ConnectViewState {
  final GenericException error;
  const Failure(this.error) : super(ConnectViewStatus.failure);
}

enum ConnectViewStatus {
  initial,
  connecting,
  connected,
  failure;
}
