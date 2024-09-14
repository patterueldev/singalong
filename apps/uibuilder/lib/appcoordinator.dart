part of 'main.dart';

class AppCoordinator
    implements ConnectNavigationCoordinator, SessionNavigationCoordinator {
  final ConnectFeatureProvider connectFeatureProvider;
  final SessionFeatureProvider sessionFeatureProvider;

  const AppCoordinator({
    required this.connectFeatureProvider,
    required this.sessionFeatureProvider,
  });

  @override
  void openSongBook(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double modalHeight = screenHeight * 0.8; // 3/4 of the screen height

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: modalHeight,
          color: Colors.white,
          child: const TemporaryScreenView(
            name: "Song Book",
          ),
        );
      },
    );
  }

  @override
  void openSession(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (context) => const TemporaryScreenView(
                name: "Song Book",
              )),
    );
  }

  @override
  void backToConnectScreen(BuildContext context) {
    Navigator.of(context).pop();
  }
}
