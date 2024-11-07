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
  final PersistenceRepository persistenceService;
  EstablishConnectionUseCase({
    required this.connectRepository,
    required this.persistenceService,
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
          if (requiresUserPasscode != null && requiresRoomPasscode != null) {
            return ConnectViewState.requiresPasscode(
              requiresUserPasscode: requiresUserPasscode,
              requiresRoomPasscode: requiresRoomPasscode,
            );
          } else if (accessToken != null) {
            // store the access token somewhere
            debugPrint("Access token: $accessToken");
            connectRepository.provideAccessToken(accessToken);
            persistenceService.saveUsername(parameters.username);
            persistenceService.saveRoomId(parameters.roomId);
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
