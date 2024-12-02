part of '../singalong_api_client.dart';

enum RoomDataType {
  reservedSongs,
  currentSong,
  playerList,
  assignedPlayerInRoom,
  participantsList,
  all,
  ;

  String get value {
    switch (this) {
      case reservedSongs:
        return 'reservedSongs';
      case currentSong:
        return 'currentSong';
      case playerList:
        return 'playerList';
      case assignedPlayerInRoom:
        return 'assignedPlayerInRoom';
      case participantsList:
        return 'participantsList';
      case all:
        return 'all';
    }
  }
}
