part of '../main.dart';

class PreviewerView extends StatefulWidget {
  const PreviewerView({super.key});

  @override
  State<StatefulWidget> createState() => _PrevierViewState();
}

class _PrevierViewState extends State<PreviewerView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<PreviewerViewModel>();
      final navigationIndex = viewModel.autoNavigationIndex;
      if (navigationIndex >= 0) {
        final navigator = viewModel.navigators[navigationIndex];
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: RouteSettings(name: navigator.name),
            builder: (context) => navigator.build(context),
          ),
        );
      }
    });
  }

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
                        settings: RouteSettings(name: navigatorItem.name),
                        builder: (context) => navigatorItem.build(context)),
                  );
                },
              );
            },
          ),
        ),
      );
}
