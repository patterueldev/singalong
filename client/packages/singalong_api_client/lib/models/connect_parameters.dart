part of '../singalong_api_client.dart';

@JsonSerializable()
class APIConnectParameters {
  final String username;
  final String? userPasscode;
  final String roomId;
  final String? roomPasscode;
  final String clientType;

  APIConnectParameters({
    required this.username,
    this.userPasscode,
    required this.roomId,
    this.roomPasscode,
    required this.clientType,
  });

  factory APIConnectParameters.fromJson(Map<String, dynamic> json) =>
      _$APIConnectParametersFromJson(json);
  Map<String, dynamic> toJson() => _$APIConnectParametersToJson(this);
}
