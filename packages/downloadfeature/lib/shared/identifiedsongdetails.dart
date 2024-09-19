part of '../downloadfeature.dart';

class IdentifiedSongDetails {
  final String id;
  final String source;
  final String imageUrl;
  final String songTitle;
  final String songArtist;
  final String songLanguage;
  final bool isOffVocal;
  final bool videoHasLyrics;
  final String songLyrics;

  IdentifiedSongDetails({
    required this.id,
    required this.source,
    required this.imageUrl,
    required this.songTitle,
    required this.songArtist,
    required this.songLanguage,
    required this.isOffVocal,
    required this.videoHasLyrics,
    required this.songLyrics,
  });

  factory IdentifiedSongDetails.fake() => IdentifiedSongDetails(
        id: '123',
        source: 'ourtube',
        imageUrl: 'https://via.placeholder.com/150',
        songTitle: 'Fake Title',
        songArtist: 'Fake Artist',
        songLanguage: 'Fake Language',
        isOffVocal: false,
        videoHasLyrics: false,
        songLyrics: 'Fake Lyrics',
      );
}
