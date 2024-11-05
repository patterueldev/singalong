part of '../singalong_api_client.dart';

@JsonSerializable()
class APISaveSongParameters {
  final bool thenReserve;
  final APIIdentifiedSongDetails song;

  APISaveSongParameters({
    required this.thenReserve,
    required this.song,
  });

  factory APISaveSongParameters.fromJson(Map<String, dynamic> json) =>
      _$APISaveSongParametersFromJson(json);
  Map<String, dynamic> toJson() => _$APISaveSongParametersToJson(this);

  @override
  String toString() {
    return 'SaveSongParameters(thenReserve: $thenReserve, song: $song)';
  }
}
