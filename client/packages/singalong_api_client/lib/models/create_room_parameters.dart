part of '../singalong_api_client.dart';

@JsonSerializable()
class APICreateRoomParameters {
  final String roomId;
  final String roomName;
  final String roomPasscode;

  APICreateRoomParameters({
    required this.roomId,
    required this.roomName,
    this.roomPasscode = '',
  });

  factory APICreateRoomParameters.fromJson(Map<String, dynamic> json) =>
      _$APICreateRoomParametersFromJson(json);
  Map<String, dynamic> toJson() => _$APICreateRoomParametersToJson(this);
}
