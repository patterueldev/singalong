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
      if (viewModel.navigateOnStartup) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => viewModel.navigators.first.build(context),
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
                        builder: (context) => navigatorItem.build(context)),
                  );
                },
              );
            },
          ),
        ),
      );
}
