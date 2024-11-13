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
  })  : singalongConfigurationNotifier = ValueNotifier(singalongConfiguration),
        super() {
    usernameController.text = username;
    passwordController.text = password;
  }

  late final SignInUseCase signInUseCase = SignInUseCase(
    connectRepository: connectRepository,
    persistenceRepository: persistenceRepository,
  );

  @override
  final ValueNotifier<SingalongConfiguration> singalongConfigurationNotifier;

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
