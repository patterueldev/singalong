// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'singalong_api_client.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

APIConnectParameters _$APIConnectParametersFromJson(
        Map<String, dynamic> json) =>
    APIConnectParameters(
      username: json['username'] as String,
      userPasscode: json['userPasscode'] as String?,
      roomId: json['roomId'] as String,
      roomPasscode: json['roomPasscode'] as String?,
      clientType: json['clientType'] as String,
    );

Map<String, dynamic> _$APIConnectParametersToJson(
        APIConnectParameters instance) =>
    <String, dynamic>{
      'username': instance.username,
      'userPasscode': instance.userPasscode,
      'roomId': instance.roomId,
      'roomPasscode': instance.roomPasscode,
      'clientType': instance.clientType,
    };

GenericResponse _$GenericResponseFromJson(Map<String, dynamic> json) =>
    GenericResponse(
      success: json['success'] as bool,
      status: (json['status'] as num).toInt(),
      data: json['data'],
      message: json['message'] as String?,
    );

Map<String, dynamic> _$GenericResponseToJson(GenericResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'status': instance.status,
      'data': instance.data,
      'message': instance.message,
    };

APIConnectResponseData _$APIConnectResponseDataFromJson(
        Map<String, dynamic> json) =>
    APIConnectResponseData(
      requiresUserPasscode: json['requiresUserPasscode'] as bool?,
      requiresRoomPasscode: json['requiresRoomPasscode'] as bool?,
      accessToken: json['accessToken'] as String?,
    );

Map<String, dynamic> _$APIConnectResponseDataToJson(
        APIConnectResponseData instance) =>
    <String, dynamic>{
      'requiresUserPasscode': instance.requiresUserPasscode,
      'requiresRoomPasscode': instance.requiresRoomPasscode,
      'accessToken': instance.accessToken,
    };
