part of '../adminfeature.dart';

abstract class SignInViewModel extends ChangeNotifier {
  String username = '';
  String password = '';
  ValueNotifier<bool> isLoading = ValueNotifier(false);

  void signIn();
  void clear() {
    username = '';
    password = '';
    notifyListeners();
  }
}

class DefaultSignInViewModel extends SignInViewModel {
  DefaultSignInViewModel();

  @override
  void signIn() async {
    // TODO: Implement sign in
  }
}
