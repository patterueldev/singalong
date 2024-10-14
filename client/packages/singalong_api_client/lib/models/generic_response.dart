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
