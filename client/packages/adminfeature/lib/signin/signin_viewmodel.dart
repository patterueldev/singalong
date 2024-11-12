part of '../adminfeature.dart';

abstract class SignInViewModel extends ChangeNotifier {
  ValueNotifier<bool> isLoading = ValueNotifier(false);
  ValueNotifier<String?> toastMessage = ValueNotifier(null);
  ValueNotifier<bool> isSignedIn = ValueNotifier(false);
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  ValueNotifier<SingalongConfiguration> get singalongConfigurationNotifier;

  void signIn();

  void updateServerHost(String host);
  void resetServerHost();
}

class DefaultSignInViewModel extends SignInViewModel {
  final ConnectRepository connectRepository;
  final PersistenceRepository persistenceRepository;

  DefaultSignInViewModel({
    required this.connectRepository,
    required this.persistenceRepository,
    required SingalongConfiguration singalongConfiguration,
    String username = '',
    String password = '',
  }) : super() {
    usernameController.text = username;
    passwordController.text = password;
    singalongConfigurationNotifier = ValueNotifier(singalongConfiguration);
  }

  late final SignInUseCase signInUseCase = SignInUseCase(
    connectRepository: connectRepository,
    persistenceRepository: persistenceRepository,
  );

  @override
  late final ValueNotifier<SingalongConfiguration>
      singalongConfigurationNotifier;

  @override
  void signIn() async {
    isLoading.value = true;

    final result = await signInUseCase(ConnectParameters.admin(
      username: usernameController.text,
      userPasscode: passwordController.text,
    ));
    result.fold(
      (exception) {
        toastMessage.value = exception.toString();
        isLoading.value = false;
      },
      (_) {
        debugPrint('Sign in successful');
        isSignedIn.value = true;
        // keep isLoading true to prevent user from interacting with the UI
      },
    );
  }

  @override
  void updateServerHost(String host) async {
    isLoading.value = true;
    persistenceRepository.saveCustomHost(host);
    singalongConfigurationNotifier.value.customHost = host;
    singalongConfigurationNotifier.notifyListeners();
    isLoading.value = false;
  }

  @override
  void resetServerHost() async {
    isLoading.value = true;
    await persistenceRepository.clearCustomHost();
    singalongConfigurationNotifier.value.customHost = null;
    singalongConfigurationNotifier.notifyListeners();
    isLoading.value = false;
  }
}

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