part of 'connectfeature.dart';

class ConnectViewState {
  const ConnectViewState(this.type);

  final ConnectViewStateType type;

  factory ConnectViewState.initial() =>
      const ConnectViewState(ConnectViewStateType.initial);
  factory ConnectViewState.connecting() =>
      const ConnectViewState(ConnectViewStateType.connecting);
  factory ConnectViewState.connected() =>
      const ConnectViewState(ConnectViewStateType.connected);
  factory ConnectViewState.failure(GenericException error) => Failure(error);
}

class Failure extends ConnectViewState {
  final GenericException error;
  const Failure(this.error) : super(ConnectViewStateType.failure);
}

enum ConnectViewStateType {
  initial,
  connecting,
  connected,
  failure;
}
