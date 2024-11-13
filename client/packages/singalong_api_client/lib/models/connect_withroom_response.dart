part of '../singalong_api_client.dart';

@JsonSerializable()
class APIConnectWithRoomResponseData {
  final String accessToken;
  final String refreshToken;

  APIConnectWithRoomResponseData({
    required this.accessToken,
    required this.refreshToken,
  });

  factory APIConnectWithRoomResponseData.fromJson(Map<String, dynamic> json) =>
      _$APIConnectWithRoomResponseDataFromJson(json);
  Map<String, dynamic> toJson() => _$APIConnectWithRoomResponseDataToJson(this);
}
