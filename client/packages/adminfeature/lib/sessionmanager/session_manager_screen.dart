part of '../adminfeature.dart';

class SessionManagerScreen extends StatefulWidget {
  const SessionManagerScreen({super.key});

  @override
  State<SessionManagerScreen> createState() => _SessionManagerScreenState();
}

class _SessionManagerScreenState extends State<SessionManagerScreen> {
  @override
  Widget build(BuildContext context) => Consumer<SessionManagerViewModel>(
        builder: (context, viewModel, child) => Stack(
          children: [
            _buildScaffold(viewModel),
            ValueListenableBuilder(
                valueListenable: viewModel.isLoadingNotifier,
                builder: (context, isLoading, child) {
                  if (isLoading) {
                    return Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
          ],
        ),
      );

  Widget _buildScaffold(SessionManagerViewModel viewModel) => Scaffold(
        appBar: AppBar(
          leading: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'disconnect') {
                // viewModel.disconnect();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'disconnect',
                  child: Text("Disconnect"),
                ),
              ];
            },
            icon: const Icon(Icons.menu),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => viewModel.createRoom(),
            ),
          ],
        ),
        body: SafeArea(
          child: Container(
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // create new room button

                  const SizedBox(height: 16),
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: viewModel.roomsNotifier,
                      builder: (context, rooms, child) => ListView.builder(
                        itemCount: rooms.length,
                        itemBuilder: (context, index) =>
                            _buildRoomItem(rooms[index]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildRoomItem(Room room) => InkWell(
        onTap: () => {},
        child: Opacity(
          opacity: room.isActive ? 1.0 : 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(room.name),
              Text('ID: ${room.id}'),
              if (!room.isActive && room.lastActive != null)
                Text('Last Active: ${room.lastActive}'),
              Text(room.isSecured ? 'Secured' : 'Unsecured'),
              const Divider(),
            ],
          ),
        ),
      );
}
