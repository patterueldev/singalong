part of '../singalong_api_client.dart';

@JsonSerializable()
class APICurrentSong {
  final String id;
  final String title;
  final String artist;
  final String thumbnailPath;
  final String videoPath;
  final int durationInSeconds;
  final String reservingUser;
  final double volume;

  APICurrentSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailPath,
    required this.videoPath,
    required this.durationInSeconds,
    required this.reservingUser,
    this.volume = 1.0,
  });

  factory APICurrentSong.fromJson(Map<String, dynamic> json) =>
      _$APICurrentSongFromJson(json);
  static List<APICurrentSong> fromList(List<dynamic> list) {
    return list.map((e) => APICurrentSong.fromJson(e)).toList();
  }

  Map<String, dynamic> toJson() => _$APICurrentSongToJson(this);
  factory APICurrentSong.fromResponse(Response response) {
    return APICurrentSong.fromJson(json.decode(response.body));
  }

  @override
  String toString() {
    return 'APICurrentSong(id: $id, title: $title, artist: $artist, thumbnailPath: $thumbnailPath, videoPath: $videoPath, reservingUser: $reservingUser)';
  }
}
