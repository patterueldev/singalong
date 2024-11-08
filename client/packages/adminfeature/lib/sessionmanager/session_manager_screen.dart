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
                  ElevatedButton(
                    child: const Text('Create New Room'),
                    onPressed: () => viewModel.load(),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: viewModel.roomsNotifier,
                      builder: (context, rooms, child) => ListView.builder(
                        itemCount: rooms.length,
                        itemBuilder: (context, index) {
                          final room = rooms[index];
                          return InkWell(
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
                                  Text(room.isSecured ? 'Secured' : 'Unecured'),
                                  const Divider(),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
