part of '../_main.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Singalong Admin',
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.dark,
        home: Consumer<AdminAppViewModel>(
          builder: (context, viewModel, child) {
            final adminFeatureUIProvider =
                context.read<AdminFeatureUIProvider>();
            switch (viewModel.authenticationState.status) {
              case AuthenticationStatus.loading:
                return const StartUpScreen();
              case AuthenticationStatus.unauthenticated:
                return adminFeatureUIProvider.buildSignInScreen(context,
                    username: 'pat', password: '1234');
              case AuthenticationStatus.authenticated:
                return adminFeatureUIProvider
                    .buildSessionManagerScreen(context);
            }
          },
        ),
      );
}

class StartUpScreen extends StatelessWidget {
  const StartUpScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
}

class AuthenticationState {
  final AuthenticationStatus status;

  const AuthenticationState.unauthenticated()
      : status = AuthenticationStatus.unauthenticated;
  const AuthenticationState.authenticated()
      : status = AuthenticationStatus.authenticated;
}

enum AuthenticationStatus {
  loading,
  unauthenticated,
  authenticated,
}
