part of '../singalong_api_client.dart';

@JsonSerializable()
class APIPaginatedRoomList {
  final List<APIRoomItem> items;
  final int? nextOffset;
  final String? nextCursor;
  final int? nextPage;

  APIPaginatedRoomList({
    required this.items,
    this.nextOffset,
    this.nextCursor,
    this.nextPage,
  });

  factory APIPaginatedRoomList.fromJson(Map<String, dynamic> json) =>
      _$APIPaginatedRoomListFromJson(json);
  Map<String, dynamic> toJson() => _$APIPaginatedRoomListToJson(this);
}

@JsonSerializable()
class APIRoomItem {
  final String id;
  final String name;
  final bool isSecured;
  final bool isActive;
  final DateTime lastActive;

  APIRoomItem({
    required this.id,
    required this.name,
    required this.isSecured,
    required this.isActive,
    required this.lastActive,
  });

  factory APIRoomItem.fromJson(Map<String, dynamic> json) =>
      _$APIRoomItemFromJson(json);
  Map<String, dynamic> toJson() => _$APIRoomItemToJson(this);
}

@JsonSerializable()
class APILoadRoomListParameters {
  final String? keyword;
  final int? limit;
  final int? nextOffset;
  final String? nextCursor;
  final int? nextPage;

  APILoadRoomListParameters({
    this.keyword,
    this.limit,
    this.nextOffset,
    this.nextCursor,
    this.nextPage,
  });

  factory APILoadRoomListParameters.fromJson(Map<String, dynamic> json) =>
      _$APILoadRoomListParametersFromJson(json);
  Map<String, dynamic> toJson() => _$APILoadRoomListParametersToJson(this);
}

@JsonSerializable()
class APIRoom {
  final String id;
  final String name;
  final String? passcode;
  final bool isArchived;

  APIRoom({
    required this.id,
    required this.name,
    this.passcode,
    required this.isArchived,
  });

  factory APIRoom.fromJson(Map<String, dynamic> json) =>
      _$APIRoomFromJson(json);
  Map<String, dynamic> toJson() => _$APIRoomToJson(this);
}
