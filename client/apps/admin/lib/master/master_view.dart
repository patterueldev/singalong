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
          leading: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'select_room') {
                Navigator.of(context).pop();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'select_room',
                  child: Text("Select Room"),
                ),
              ];
            },
            icon: const Icon(Icons.menu),
          ),
          title: Text('${viewModel.room.name} (${viewModel.room.id})'),
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
              child: _buildLeftHalf(context, viewModel),
            ),
            const VerticalDivider(),
            // Right half
            Expanded(
              flex: 1,
              child: _buildRightHalf(context),
            ),
          ],
        ),
      );

  Widget _buildLeftHalf(BuildContext context, MasterViewModel viewModel) =>
      Column(
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
            child: _buildBottomLeft(context),
          ),
        ],
      );

  // Player Control Panel
  Widget _buildTopLeft(BuildContext context, MasterViewModel viewModel) =>
      context
          .read<AdminFeatureUIProvider>()
          .buildPlayerControlPanel(viewModel.room);

  Widget _buildBottomLeft(BuildContext context) =>
      context.read<AdminFeatureUIProvider>().buildReservedPanel(context);

  Widget _buildRightHalf(BuildContext context) => Column(
        children: [
          // Top left quarter
          Expanded(
            flex: 3,
            child: _buildTopRight(context),
          ),
          const Divider(),
          // Bottom left quarter
          Expanded(
            flex: 2,
            child: _buildBottomRight(context),
          ),
        ],
      );

  Widget _buildTopRight(BuildContext context) =>
      context.read<SongBookFeatureProvider>().buildSongBookView(
          context: context,
          canGoBack: false,
          roomId: context.read<MasterViewModel>().room.id);

  Widget _buildBottomRight(BuildContext context) => context
      .read<AdminFeatureUIProvider>()
      .buildParticipantsPanelWidget(context);
}
