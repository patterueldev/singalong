part of '../commonds.dart';

class UserParticipantSocketRepositoryDS
    implements UserParticipantSocketRepository {
  final SingalongSocket socket;

  UserParticipantSocketRepositoryDS({
    required this.socket,
  });

  @override
  StreamController<List<UserParticipant>> get participantsController =>
      socket.buildRoomEventStreamController(
        SocketEvent.participantsList,
        (data, controller) {
          debugPrint('Participants list received (raw): $data');
          final raw = APIRoomParticipant.fromList(data);
          final participants = raw
              .map(
                (e) => UserParticipant(
                  name: e.name,
                  songsFinished: e.songsFinished,
                  songsUpcoming: e.songsUpcoming,
                ),
              )
              .toList();
          controller.add(participants);
        },
      );

  @override
  void requestParticipantsList() {
    socket.emitRoomDataRequestEvent([RoomDataType.participantsList]);
  }
}
