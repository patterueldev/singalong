part of 'adminfeatureds.dart';

class PlayerSocketRepositoryDS implements PlayerSocketRepository {
  final SingalongAPI api;
  final SingalongSocket socket;
  final SingalongConfiguration configuration;

  PlayerSocketRepositoryDS({
    required this.api,
    required this.socket,
    required this.configuration,
  });

  @override
  void requestPlayerList() {
    debugPrint("requestPlayerList");
    socket.emitEvent(SocketEvent.requestPlayersList, "Please");
  }

  @override
  Future<void> assignPlayerToRoom(PlayerItem player, Room room) async {
    await api.assignPlayerToRoom(player.name, room.id);
  }

  @override
  StreamController<List<PlayerItem>> get playersStreamController {
    debugPrint("playersStreamController");
    return socket.buildEventStreamController(
      SocketEvent.playersList,
      (data, controller) {
        debugPrint("playersStreamController Data: $data");
        final raw = APIPlayerItem.fromList(data);
        final players = raw
            .map(
              (e) => PlayerItem(
                id: e.id,
                name: e.name,
                isIdle: true,
              ),
            )
            .toList();
        controller.add(players);
      },
    );
  }
}
