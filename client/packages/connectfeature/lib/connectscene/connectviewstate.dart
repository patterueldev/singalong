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
  factory ConnectViewState.requiresPasscode({
    required bool requiresUserPasscode,
    required bool requiresRoomPasscode,
  }) =>
      RequiresPasscode(
        requiresUserPasscode: requiresUserPasscode,
        requiresRoomPasscode: requiresRoomPasscode,
      );
  factory ConnectViewState.failure(GenericException error) => Failure(error);
}

class RequiresPasscode extends ConnectViewState {
  final bool requiresUserPasscode;
  final bool requiresRoomPasscode;

  RequiresPasscode({
    required this.requiresUserPasscode,
    required this.requiresRoomPasscode,
  }) : super(ConnectViewStatus.requiresPasscode);
}

class Failure extends ConnectViewState {
  final GenericException error;
  const Failure(this.error) : super(ConnectViewStatus.failure);
}

enum ConnectViewStatus {
  initial,
  connecting,
  connected,
  requiresPasscode,
  failure;
}
