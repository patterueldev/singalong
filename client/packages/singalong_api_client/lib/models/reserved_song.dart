part of '../singalong_api_client.dart';

@JsonSerializable()
class APIReservedSong {
  final String id;
  final int order;
  final String songId;
  final String title;
  final String artist;
  final String thumbnailPath;
  final String reservingUser;
  final bool currentPlaying;

  APIReservedSong({
    required this.id,
    required this.order,
    required this.songId,
    required this.title,
    required this.artist,
    required this.thumbnailPath,
    required this.reservingUser,
    required this.currentPlaying,
  });

  factory APIReservedSong.fromJson(Map<String, dynamic> json) =>
      _$APIReservedSongFromJson(json);
  static List<APIReservedSong> fromList(List<dynamic> list) {
    return list.map((e) => APIReservedSong.fromJson(e)).toList();
  }

  Map<String, dynamic> toJson() => _$APIReservedSongToJson(this);
  factory APIReservedSong.fromResponse(Response response) {
    return APIReservedSong.fromJson(json.decode(response.body));
  }

  @override
  String toString() {
    return 'APIReservedSong(id: $id, order: $order, songId: $songId, title: $title, artist: $artist, imageURL: $thumbnailPath, reservingUser: $reservingUser, currentPlaying: $currentPlaying)';
  }
}
