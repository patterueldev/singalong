part of '../connectfeature.dart';

abstract class EstablishConnectionUseCase {
  TaskEither<GenericException, ConnectViewState> connect(
      String name, String sessionId);
}

class DefaultEstablishConnectionUseCase implements EstablishConnectionUseCase {
  final ConnectRepository connectRepository;
  DefaultEstablishConnectionUseCase({
    required this.connectRepository,
  });
  @override
  TaskEither<GenericException, ConnectViewState> connect(
          String name, String sessionId) =>
      TaskEither.tryCatch(() async {
        debugPrint("Attempting to connect");
        if (name.isEmpty) {
          throw ConnectException.emptyName();
        }
        if (sessionId.isEmpty) {
          throw ConnectException.emptySessionId();
        }

        final result = await connectRepository.connect(
          ConnectParameters(
            username: name,
            userPasscode: null,
            roomId: sessionId,
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
          throw GenericException.unhandled(accessToken); //TODO: remove this
        }
        throw GenericException.unknown();
      }, (e, s) {
        if (e is GenericException) {
          return e;
        }
        return GenericException.unhandled(e);
      });
}
