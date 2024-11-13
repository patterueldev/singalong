part of '../singalong_api_client.dart';

@JsonSerializable()
class APIConnectResponseData {
  final bool? requiresUserPasscode;
  final bool? requiresRoomPasscode;
  final String? accessToken;
  final String? refreshToken;

  APIConnectResponseData({
    this.requiresUserPasscode,
    this.requiresRoomPasscode,
    this.accessToken,
    this.refreshToken,
  });

  factory APIConnectResponseData.fromJson(Map<String, dynamic> json) =>
      _$APIConnectResponseDataFromJson(json);
  Map<String, dynamic> toJson() => _$APIConnectResponseDataToJson(this);
  factory APIConnectResponseData.fromResponse(Response response) {
    return APIConnectResponseData.fromJson(json.decode(response.body));
  }

  @override
  String toString() {
    return 'ConnectResponseData(requiresUserPasscode: $requiresUserPasscode, requiresRoomPasscode: $requiresRoomPasscode, accessToken: $accessToken)';
  }
}
