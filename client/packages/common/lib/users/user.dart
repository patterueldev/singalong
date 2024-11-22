part of '../common.dart';

class UserParticipant {
  final String name;
  final int songsFinished;
  final int songsUpcoming;

  UserParticipant({
    required this.name,
    required this.songsFinished,
    required this.songsUpcoming,
  });
}

abstract class UserParticipantSocketRepository {
  StreamController<List<UserParticipant>> get participantsController;

  void requestParticipantsList();
}
