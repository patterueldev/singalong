part of '../connectfeature.dart';

abstract class ConnectRepository {
  Future<ConnectResponse> connect(ConnectParameters parameters);
}

class ConnectParameters {
  final String username;
  final String? userPasscode;
  final String roomId;
  final String? roomPasscode;
  final String clientType;

  ConnectParameters({
    required this.username,
    this.userPasscode,
    required this.roomId,
    this.roomPasscode,
    required this.clientType,
  });
}

class ConnectResponse {
  final bool? requiresUserPasscode;
  final bool? requiresRoomPasscode;
  final String? accessToken;

  ConnectResponse({
    this.requiresUserPasscode,
    this.requiresRoomPasscode,
    this.accessToken,
  });
}

/*

@JsonSerializable()
class APIConnectResponseData {
  final bool? requiresUserPasscode;
  final bool? requiresRoomPasscode;
  final String? accessToken;

  APIConnectResponseData({
    this.requiresUserPasscode,
    this.requiresRoomPasscode,
    this.accessToken,
  });

  factory APIConnectResponseData.fromJson(Map<String, dynamic> json) =>
      _$ConnectResponseDataFromJson(json);
  Map<String, dynamic> toJson() => _$ConnectResponseDataToJson(this);
  factory APIConnectResponseData.fromResponse(Response response) {
    return APIConnectResponseData.fromJson(json.decode(response.body));
  }

  @override
  String toString() {
    return 'ConnectResponseData(requiresUserPasscode: $requiresUserPasscode, requiresRoomPasscode: $requiresRoomPasscode, accessToken: $accessToken)';
  }
}

 */
