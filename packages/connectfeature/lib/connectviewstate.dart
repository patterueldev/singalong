part of 'connectfeature.dart';

class ConnectViewState {
  const ConnectViewState();

  factory ConnectViewState.initial() = Initial;
  factory ConnectViewState.connecting() = Connecting;
  factory ConnectViewState.connected() = Connected;
  factory ConnectViewState.failure(String error) = Failure;
}

class Initial extends ConnectViewState {
  const Initial();
}

class Connecting extends ConnectViewState {
  const Connecting();
}

class Connected extends ConnectViewState {
  const Connected();
}

class Failure extends ConnectViewState {
  final String error;
  const Failure(this.error);
}
