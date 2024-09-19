part of '../connectfeature.dart';

abstract class EstablishConnectionUseCase {
  TaskEither<GenericException, Unit> connect(String name, String sessionId);
}

class DefaultEstablishConnectionUseCase implements EstablishConnectionUseCase {
  DefaultEstablishConnectionUseCase();
  @override
  TaskEither<GenericException, Unit> connect(String name, String sessionId) =>
      TaskEither.tryCatch(() async {
        debugPrint("Attempting to connect");
        if (name.isEmpty) {
          throw ConnectException.emptyName();
        }
        if (sessionId.isEmpty) {
          throw ConnectException.emptySessionId();
        }
        await Future.delayed(const Duration(seconds: 2));

        // obviously, session connection goes first; actually alongside the name
        // if app can't find session, throw session error
        // otherwise, app will check if session already uses the name
        final temporaryValidSessionIDs = ["123456"];
        if (!temporaryValidSessionIDs.contains(sessionId)) {
          throw ConnectException.invalidSessionId(sessionId);
        }

        final temporaryExistingName = ["thor"];
        if (temporaryExistingName.contains(name)) {
          throw ConnectException.invalidName(name);
        }

        return unit;
      }, (e, s) {
        if (e is GenericException) {
          return e;
        }
        return GenericException.unhandled(e);
      });
}
