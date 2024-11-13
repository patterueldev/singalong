part of '../_main.dart';

class MasterView extends StatelessWidget {
  const MasterView({super.key});

  @override
  Widget build(BuildContext context) => Consumer<MasterViewModel>(
        builder: (context, viewModel, child) {
          return _buildScaffold(context, viewModel);
        },
      );

  Widget _buildScaffold(BuildContext context, MasterViewModel viewModel) =>
      Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              // Handle menu button press
            },
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1.0),
            child: Divider(),
          ),
        ),
        body: Row(
          children: [
            // Left half
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  // Top left quarter
                  Expanded(
                    flex: 1,
                    child: _buildTopLeft(context, viewModel),
                  ),
                  const Divider(),
                  // Bottom left quarter
                  Expanded(
                    flex: 2,
                    child: _buildBottomLeft(),
                  ),
                ],
              ),
            ),
            const VerticalDivider(),
            // Right half
            Expanded(
              flex: 1,
              child: _buildRightHalf(),
            ),
          ],
        ),
      );

  // Player Control Panel
  Widget _buildTopLeft(BuildContext context, MasterViewModel viewModel) =>
      context.read<AdminFeatureUIProvider>().buildPlayerControlPanel();

  Widget _buildBottomLeft() => Container(
        child: Center(child: Text('Bottom Left Corner')),
      );

  Widget _buildRightHalf() => Container(
        child: Center(child: Text('Right Half Edge')),
      );
}
