part of '../_main.dart';

abstract class AdminAppViewModel extends ChangeNotifier {
  AuthenticationState authenticationState =
      const AuthenticationState.unauthenticated();

  void checkAuthentication();
}

class DefaultAdminAppViewModel extends AdminAppViewModel {
  final ConnectRepository connectRepository;

  DefaultAdminAppViewModel({
    required this.connectRepository,
  }) {
    checkAuthentication();
  }

  @override
  void checkAuthentication() async {
    final isAuthenticated = await connectRepository.checkAuthentication();
    if (isAuthenticated) {
      authenticationState = const AuthenticationState.authenticated();
    } else {
      authenticationState = const AuthenticationState.unauthenticated();
    }
    notifyListeners();
  }
}
