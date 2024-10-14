part of '../singalong_api_client.dart';

@JsonSerializable()
class APIReservedSong {
  final String id;
  final int order;
  final String songId;
  final String title;
  final String artist;
  final String imageURL;
  final String reservingUser;
  final bool currentPlaying;

  APIReservedSong({
    required this.id,
    required this.order,
    required this.songId,
    required this.title,
    required this.artist,
    required this.imageURL,
    required this.reservingUser,
    required this.currentPlaying,
  });

  factory APIReservedSong.fromJson(Map<String, dynamic> json) =>
      _$APIReservedSongFromJson(json);
  Map<String, dynamic> toJson() => _$APIReservedSongToJson(this);
  factory APIReservedSong.fromResponse(Response response) {
    return APIReservedSong.fromJson(json.decode(response.body));
  }

  @override
  String toString() {
    return 'APIReservedSong(id: $id, order: $order, songId: $songId, title: $title, artist: $artist, imageURL: $imageURL, reservingUser: $reservingUser, currentPlaying: $currentPlaying)';
  }
}
/*

interface ReservedSong {
    val id: String
    val order: Int
    val songId: String
    val title: String
    val artist: String
    val imageURL: String
    val reservingUser: String
    val currentPlaying: Boolean
}

 */
