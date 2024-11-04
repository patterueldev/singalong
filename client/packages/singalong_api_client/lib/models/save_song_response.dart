part of '../singalong_api_client.dart';

@JsonSerializable()
class APISaveSongResponseData {
  final String id;
  final String source;
  final String sourceId;
  final String thumbnailPath;
  final String videoPath;
  final String songTitle;
  final String songArtist;
  final String songLanguage;
  final bool isOffVocal;
  final bool videoHasLyrics;
  final String songLyrics;
  final int lengthSeconds;

  APISaveSongResponseData({
    required this.id,
    required this.source,
    required this.sourceId,
    required this.thumbnailPath,
    required this.videoPath,
    required this.songTitle,
    required this.songArtist,
    required this.songLanguage,
    required this.isOffVocal,
    required this.videoHasLyrics,
    required this.songLyrics,
    required this.lengthSeconds,
  });

  factory APISaveSongResponseData.fromJson(Map<String, dynamic> json) =>
      _$APISaveSongResponseDataFromJson(json);

  Map<String, dynamic> toJson() => _$APISaveSongResponseDataToJson(this);
}
/*
{
    "success": true,
    "status": 200,
    "data": {
        "id": "67289505dd458d760dfcffba",
        "source": "https://www.youtube.com/watch?v=JAotjuGdoQ4",
        "sourceId": "JAotjuGdoQ4",
        "thumbnailPath": "thumbnails/[歌詞・音程バーカラオケ-練習用]-μ`s---僕らのlive-君とのlife-(アニメ`ラブライブ!`ost)-【原曲キー】-♪-j-pop-karaoke[JAotjuGdoQ4].jpg",
        "videoPath": "videos/[歌詞・音程バーカラオケ-練習用]-μ`s---僕らのlive-君とのlife-(アニメ`ラブライブ!`ost)-【原曲キー】-♪-j-pop-karaoke[JAotjuGdoQ4].mp4",
        "songTitle": "[歌詞・音程バーカラオケ/練習用] μ`s - 僕らのLIVE 君とのLIFE (アニメ`ラブライブ!`OST) 【原曲キー】 ♪ J-POP Karaoke",
        "songArtist": "Unknown Artist",
        "songLanguage": "Unknown",
        "isOffVocal": false,
        "videoHasLyrics": false,
        "songLyrics": "",
        "lengthSeconds": 330
    },
    "message": null
}
 */
