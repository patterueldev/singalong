part of '../connectfeature.dart';

abstract class ServiceUseCase<P, R> {
  TaskEither<GenericException, R> task(P parameters);

  Future<Either<GenericException, R>> call(P parameters) {
    return task(parameters).run();
  }
}

class EstablishConnectionParameters {
  final String name;
  final String sessionId;
  EstablishConnectionParameters({
    required this.name,
    required this.sessionId,
  });
}

class EstablishConnectionUseCase
    extends ServiceUseCase<EstablishConnectionParameters, ConnectViewState> {
  final ConnectRepository connectRepository;
  EstablishConnectionUseCase({
    required this.connectRepository,
  });

  @override
  TaskEither<GenericException, ConnectViewState> task(
          EstablishConnectionParameters parameters) =>
      TaskEither.tryCatch(
        () async {
          debugPrint("Attempting to connect");
          if (parameters.name.isEmpty) {
            throw ConnectException.emptyName();
          }
          if (parameters.sessionId.isEmpty) {
            throw ConnectException.emptySessionId();
          }

          final result = await connectRepository.connect(
            ConnectParameters(
              username: parameters.name,
              userPasscode: null,
              roomId: parameters.sessionId,
              roomPasscode: null,
              clientType: "CONTROLLER",
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
            // throw GenericException.unhandled(accessToken); //TODO: remove this
            // TODO: IMPLEMENT ACCESS TOKEN STORAGE
            connectRepository.provideAccessToken(accessToken);
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
