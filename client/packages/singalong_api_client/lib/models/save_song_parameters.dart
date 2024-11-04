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
/*
{
    "thenReserve": true,
    "song": {
        "id": "JAotjuGdoQ4",
        "source": "https://www.youtube.com/watch?v=JAotjuGdoQ4",
        "imageUrl": "https://i.ytimg.com/vi/JAotjuGdoQ4/hqdefault.jpg?sqp=-oaymwEbCKgBEF5IVfKriqkDDggBFQAAiEIYAXABwAEG&rs=AOn4CLBtYIkyTHRI607yvHUPEQhBIj4qBA",
        "songTitle": "[歌詞・音程バーカラオケ/練習用] μ`s - 僕らのLIVE 君とのLIFE (アニメ`ラブライブ!`OST) 【原曲キー】 ♪ J-POP Karaoke",
        "songArtist": "Unknown Artist",
        "songLanguage": "Unknown",
        "isOffVocal": false,
        "videoHasLyrics": false,
        "songLyrics": "",
        "lengthSeconds": 330,
        "alreadyExists": false
    }
}
 */
