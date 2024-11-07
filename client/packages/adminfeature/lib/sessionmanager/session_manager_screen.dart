part of '../adminfeature.dart';

class Room {
  final String id;
  final String name;
  final bool isSecured;
  final bool isActive;
  final DateTime? lastActive;

  Room({
    required this.id,
    required this.name,
    required this.isSecured,
    required this.isActive,
    this.lastActive,
  });
}

class SessionManagerScreen extends StatefulWidget {
  const SessionManagerScreen({super.key});

  @override
  State<SessionManagerScreen> createState() => _SessionManagerScreenState();
}

class _SessionManagerScreenState extends State<SessionManagerScreen> {
  final List<Room> rooms = [
    Room(id: '1', name: 'Room 1', isSecured: true, isActive: true),
    Room(
        id: '2',
        name: 'Room 2',
        isSecured: false,
        isActive: false,
        lastActive: DateTime.now().subtract(Duration(days: 1))),
    // Add more rooms as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    child: const Text('Create New Room'), onPressed: () {}),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
