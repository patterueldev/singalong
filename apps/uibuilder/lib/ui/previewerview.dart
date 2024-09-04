part of '../main.dart';

class NavigatorItem {
  final String name;
  final Widget Function(BuildContext) destination;

  const NavigatorItem({required this.name, required this.destination});
}

abstract class PreviewerViewModel extends ChangeNotifier {
  List<NavigatorItem> get navigators;
}

class DefaultPreviewerViewModel extends PreviewerViewModel {
  DefaultPreviewerViewModel() {
    navigators.addAll([
      NavigatorItem(
        name: "Connect",
        destination: (context) => const ConnectView(),
      ),
    ]);
  }
  @override
  List<NavigatorItem> navigators = [];
}

class PreviewerView extends StatefulWidget {
  const PreviewerView({super.key});

  @override
  State<StatefulWidget> createState() => _PrevierViewState();
}

class _PrevierViewState extends State<PreviewerView> {
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.grey,
        appBar: AppBar(
          title: const Text("Test UI"),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: Consumer<PreviewerViewModel>(
          builder: (context, viewModel, child) => ListView.builder(
            itemCount: viewModel.navigators.length,
            itemBuilder: (context, index) {
              final navigatorItem = viewModel.navigators[index];
              return ListTile(
                title: Text(navigatorItem.name),
                tileColor: Colors.white,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            navigatorItem.destination(context)),
                  );
                },
              );
            },
          ),
        ),
      );
}
