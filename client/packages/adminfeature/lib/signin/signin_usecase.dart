part of '../adminfeature.dart';

class SignInUseCase extends MacroServiceUseCase<ConnectParameters, void> {
  final ConnectRepository connectRepository;
  final PersistenceRepository persistenceRepository;

  SignInUseCase({
    required this.connectRepository,
    required this.persistenceRepository,
  });

  @override
  Future<void> tryTask(ConnectParameters parameters) async {
    debugPrint("Attempting to connect");
    if (parameters.username.isEmpty) {
      throw Exception('Username cannot be empty');
    }
    if (parameters.userPasscode == null || parameters.userPasscode!.isEmpty) {
      throw Exception('Password cannot be empty');
    }

    if (parameters.roomId != "admin") {
      throw Exception('Room ID must be admin');
    }

    if (parameters.clientType != ClientType.ADMIN) {
      throw Exception('Client type must be admin');
    }

    final result = await connectRepository.connect(parameters);

    final accessToken = result.accessToken;
    if (accessToken == null) {
      throw Exception('Access token is null');
    }
    await persistenceRepository.saveAccessToken(accessToken);
    connectRepository.provideAccessToken(accessToken);
    await persistenceRepository.saveUsername(parameters.username);
    await persistenceRepository.saveRoomId(parameters.roomId);
  }
}
