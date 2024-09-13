part of 'connectfeature.dart';

abstract class ConnectUseCase {
  TaskEither<GenericException, Unit> connect(String name, String sessionId);
}

class DefaultConnectUseCase implements ConnectUseCase {
  DefaultConnectUseCase();
  @override
  TaskEither<GenericException, Unit> connect(String name, String sessionId) =>
      TaskEither.tryCatch(() async {
        if (name.isEmpty) {
          throw ConnectException.emptyName();
        }
        if (sessionId.isEmpty) {
          throw ConnectException.emptySessionId();
        }
        await Future.delayed(const Duration(seconds: 2));

        final temporaryExistingName = ["thor"];
        if (temporaryExistingName.contains(name)) {
          throw ConnectException.invalidName(name);
        }

        final temporaryValidSessionIDs = ["123456"];

        if (!temporaryValidSessionIDs.contains(sessionId)) {
          throw ConnectException.invalidSessionId(sessionId);
        }

        return unit;
      }, (e, s) {
        if (e is ConnectException) {
          return e;
        }
        return GenericException.unknown();
      });
}
