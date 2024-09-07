part of 'sessionfeature.dart';

class ReservedSongItem {
  final String title;
  final String artist;
  final String imageURL;
  final String reservingUser;
  final bool currentPlaying;

  const ReservedSongItem({
    required this.title,
    required this.artist,
    required this.imageURL,
    required this.reservingUser,
    required this.currentPlaying,
  });
}
