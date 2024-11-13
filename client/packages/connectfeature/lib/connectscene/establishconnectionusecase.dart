part of '../connectfeature.dart';

class EstablishConnectionParameters {
  final String username;
  final String roomId;
  EstablishConnectionParameters({
    required this.username,
    required this.roomId,
  });
}

class EstablishConnectionUseCase
    extends ServiceUseCase<EstablishConnectionParameters, ConnectViewState> {
  final ConnectRepository connectRepository;
  final PersistenceRepository persistenceRepository;
  EstablishConnectionUseCase({
    required this.connectRepository,
    required this.persistenceRepository,
  });

  @override
  TaskEither<GenericException, ConnectViewState> task(
          EstablishConnectionParameters parameters) =>
      TaskEither.tryCatch(
        () async {
          debugPrint("Attempting to connect");
          if (parameters.username.isEmpty) {
            throw ConnectException.emptyName();
          }
          if (parameters.roomId.isEmpty) {
            throw ConnectException.emptySessionId();
          }

          final result = await connectRepository.connect(
            ConnectParameters(
              username: parameters.username,
              userPasscode: null,
              roomId: parameters.roomId,
              roomPasscode: null,
              clientType: ClientType.CONTROLLER,
            ),
          );

          final requiresUserPasscode = result.requiresUserPasscode;
          final requiresRoomPasscode = result.requiresRoomPasscode;
          final accessToken = result.accessToken;
          final refreshToken = result.refreshToken;
          if (requiresUserPasscode != null && requiresRoomPasscode != null) {
            return ConnectViewState.requiresPasscode(
              requiresUserPasscode: requiresUserPasscode,
              requiresRoomPasscode: requiresRoomPasscode,
            );
          } else if (accessToken != null) {
            // store the access token somewhere
            debugPrint("Access token: $accessToken");
            debugPrint("Refresh token: $refreshToken");
            await persistenceRepository.saveAccessToken(accessToken);
            await persistenceRepository.saveRefreshToken(refreshToken);
            connectRepository.provideAccessToken(accessToken);
            await persistenceRepository.saveUsername(parameters.username);
            await persistenceRepository.saveRoomId(parameters.roomId);
            return ConnectViewState.connected();
          }
          throw GenericException.unknown();
        },
        (e, s) {
          if (e is GenericException) {
            return e;
          }
          return GenericException.unhandled(e);
        },
      );
}
