part of '../playerfeature.dart';

class AuthorizeConnectionUseCase
    extends ServiceUseCase<ConnectParameters, Unit> {
  final ConnectRepository connectRepository;
  AuthorizeConnectionUseCase({
    required this.connectRepository,
  });

  @override
  TaskEither<GenericException, Unit> task(ConnectParameters parameters) =>
      TaskEither.tryCatch(
        () async {
          debugPrint("Attempting to connect");
          if (parameters.username.isEmpty) {
            throw Exception("Name cannot be empty");
          }
          if (parameters.roomId.isEmpty) {
            throw Exception("Room ID cannot be empty");
          }

          final result = await connectRepository.connect(parameters);

          final requiresUserPasscode = result.requiresUserPasscode;
          final requiresRoomPasscode = result.requiresRoomPasscode;
          final accessToken = result.accessToken;
          if (requiresUserPasscode != null && requiresRoomPasscode != null) {
            throw GenericException.unhandled("Both passcodes required");
          } else if (accessToken != null) {
            // store the access token somewhere
            debugPrint("Access token: $accessToken");
            connectRepository.provideAccessToken(accessToken);
            await connectRepository.connectRoomSocket(parameters.roomId);
            return unit;
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
