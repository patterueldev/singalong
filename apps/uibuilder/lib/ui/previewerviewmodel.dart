part of '../main.dart';

abstract class PreviewerViewModel extends ChangeNotifier {
  bool get navigateOnStartup;
  List<NavigatorItem> get navigators;
}

class DefaultPreviewerViewModel extends PreviewerViewModel {
  DefaultPreviewerViewModel({
    required this.connectFeatureProvider,
    required this.sessionFeatureProvider,
    this.navigateOnStartup = true,
  });

  final ConnectFeatureProvider connectFeatureProvider;
  final SessionFeatureProvider sessionFeatureProvider;
  final TemporaryCoordinator coordinator = TemporaryCoordinator();

  @override
  final bool navigateOnStartup;

  @override
  late List<NavigatorItem> navigators = [
    NavigatorItem(
      name: "Session",
      destination: (context) => sessionFeatureProvider.buildSessionView(
          navigationDelegate: coordinator),
    ),
    NavigatorItem(
      name: "Connect",
      destination: (context) => connectFeatureProvider.buildConnectView(
        viewModel: DefaultConnectViewModel(
          name: "John Doe",
          sessionId: "123456",
        ),
      ),
    ),
  ];
}

class TemporaryCoordinator implements SessionNavigationDelegate {
  @override
  void openSongBook(
      BuildContext context, SessionViewCallbackDelegate callbackDelegate) {
    double screenHeight = MediaQuery.of(context).size.height;
    double modalHeight = screenHeight * 0.8; // 3/4 of the screen height

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: modalHeight,
          color: Colors.white,
          child: TemporarySongBookView(),
        );
      },
    );
  }
}

class TemporarySongBookView extends StatefulWidget {
  @override
  State<TemporarySongBookView> createState() => _TemporarySongBookViewState();
}

class _TemporarySongBookViewState extends State<TemporarySongBookView> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Song Book',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
