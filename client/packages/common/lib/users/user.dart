part of '../common.dart';

class UserParticipant {
  final String name;
  final int songsFinished;
  final int songsUpcoming = 0;

  UserParticipant({
    required this.name,
    required this.songsFinished,
  });
}

abstract class UserParticipantSocketRepository {
  StreamController<List<UserParticipant>> get participantsController;

  void requestParticipantsList();
}

final sampleUserParticipants = [
  UserParticipant(name: 'John', songsFinished: 10),
  UserParticipant(name: 'Jane', songsFinished: 5),
  UserParticipant(name: 'Doe', songsFinished: 3),
  UserParticipant(name: 'Smith', songsFinished: 1),
];
