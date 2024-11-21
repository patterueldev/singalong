part of '../singalong_api_client.dart';

@JsonSerializable()
class APIRoomParticipant {
  final String name;
  final int songsFinished;

  APIRoomParticipant({
    required this.name,
    required this.songsFinished,
  });

  factory APIRoomParticipant.fromJson(Map<String, dynamic> json) =>
      _$APIRoomParticipantFromJson(json);

  static List<APIRoomParticipant> fromList(List<dynamic> list) {
    return list.map((e) => APIRoomParticipant.fromJson(e)).toList();
  }
}
