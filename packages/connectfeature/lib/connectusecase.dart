part of 'connectfeature.dart';

abstract class ConnectUseCase {
  TaskEither<GenericException, Unit> connect(String name, String sessionId);
}

class DefaultConnectUseCase implements ConnectUseCase {
  DefaultConnectUseCase();
  @override
  TaskEither<GenericException, Unit> connect(String name, String sessionId) =>
      TaskEither.tryCatch(() async {
        await Future.delayed(const Duration(seconds: 2));

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
