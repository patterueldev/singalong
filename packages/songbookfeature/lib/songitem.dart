part of 'songbookfeature.dart';

class SongItem {
  final String title;
  final String artist;
  final String imageURL;
  final bool
      alreadyPlayed; // doesn't mean it can't be played again, just for indication

  const SongItem({
    required this.title,
    required this.artist,
    required this.imageURL,
    required this.alreadyPlayed,
  });
}
