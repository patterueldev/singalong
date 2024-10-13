part of '../singalong_api_client.dart';

@JsonSerializable()
class GenericResponse {
  final bool success;
  final int status;
  final dynamic data;
  final String? message;

  GenericResponse({
    required this.success,
    required this.status,
    this.data,
    this.message,
  });

  Map<String, dynamic> objectData() {
    return data as Map<String, dynamic>;
  }

  List<dynamic> arrayData() {
    return data as List<dynamic>;
  }

  factory GenericResponse.fromJson(Map<String, dynamic> json) =>
      _$GenericResponseFromJson(json);
  factory GenericResponse.fromResponse(Response response) {
    return GenericResponse.fromJson(json.decode(response.body));
  }
  Map<String, dynamic> toJson() => _$GenericResponseToJson(this);

  // Helper method to check if data is a JsonObject
  bool get isJsonObject => data is Map<String, dynamic>;

  // Helper method to check if data is a JsonArray
  bool get isJsonArray => data is List<dynamic>;

  @override
  String toString() {
    return 'GenericResponse(success: $success, status: $status, data: $data, message: $message)';
  }
}

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

/*

data class GenericResponse<T>(
    val success: Boolean,
    val status: Int,
    val data: T?,
    val message: String?,
) {
    companion object {
        fun <T> success(
            data: T,
            status: Int = 200,
            message: String? = null,
        ): GenericResponse<T> {
            return GenericResponse(
                success = true,
                status = status,
                data = data,
                message = message,
            )
        }

        fun <T> failure(
            message: String,
            status: Int = 500,
        ): GenericResponse<T> {
            return GenericResponse(
                success = false,
                status = status,
                data = null,
                message = message,
            )
        }
    }
}

 */
