part of '../singalong_api_client.dart';

@JsonSerializable()
class APIPlayerItem {
  final String id;
  final String name;
  final bool isIdle;

  APIPlayerItem({
    required this.id,
    required this.name,
    this.isIdle = false,
  });

  factory APIPlayerItem.fromJson(Map<String, dynamic> json) =>
      _$APIPlayerItemFromJson(json);
  static List<APIPlayerItem> fromList(List<dynamic> list) {
    return list.map((e) => APIPlayerItem.fromJson(e)).toList();
  }
}
