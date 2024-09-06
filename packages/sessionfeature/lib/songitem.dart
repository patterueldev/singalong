part of 'sessionfeature.dart';

class SongItem {
  final String title;
  final String artist;
  final Uri? imageURL;
  final bool currentPlaying;
  final bool canDelete;

  const SongItem({
    required this.title,
    required this.artist,
    required this.imageURL,
    required this.currentPlaying,
    required this.canDelete,
  });
}
