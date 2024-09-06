part of 'sessionfeature.dart';

class SessionViewState {
  const SessionViewState();
}

class Initial extends SessionViewState {
  const Initial();
}

class Loading extends SessionViewState {
  const Loading();
}

class Loaded extends SessionViewState {
  const Loaded();
}

class Failure extends SessionViewState {
  final String error;
  const Failure(this.error);
}
