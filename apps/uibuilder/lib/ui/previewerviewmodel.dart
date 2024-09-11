part of '../main.dart';

abstract class PreviewerViewModel extends ChangeNotifier {
  bool get navigateOnStartup;
  List<NavigatorItem> get navigators;
}

class DefaultPreviewerViewModel extends PreviewerViewModel {
  DefaultPreviewerViewModel({
    required this.connectFeatureProvider,
    required this.sessionFeatureProvider,
    this.navigateOnStartup = false,
  });

  final ConnectFeatureProvider connectFeatureProvider;
  final SessionFeatureProvider sessionFeatureProvider;

  @override
  final bool navigateOnStartup;

  @override
  late List<NavigatorItem> navigators = [
    NavigatorItem(
      name: "Session",
      build: (context) => sessionFeatureProvider.buildSessionView(
        context: context,
        coordinator: context.read(),
        localizations: context.read(),
      ),
    ),
    NavigatorItem(
      name: "Connect",
      build: (context) => connectFeatureProvider.buildConnectView(
        context: context,
        coordinator: context.read(),
        localizations: context.read(),
        name: "John Doe",
        sessionId: "123456",
      ),
    ),
  ];
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
