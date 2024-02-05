part of '../../reservations_feature.dart';

abstract class ReservationsViewModel extends ChangeNotifier {
  List<Song> get songs;
  void songBook();
}

class DefaultReservationsViewModel extends ReservationsViewModel {
  DefaultReservationsViewModel();

  @override
  List<Song> songs = [];

  @override
  void songBook() {}
}

class PreviewReservationsViewModel extends ReservationsViewModel {
  PreviewReservationsViewModel();

  @override
  List<Song> songs = [
    DefaultSong(
      title: 'Song Title',
      artist: 'Song Artist',
      album: 'Song Album',
      imageUrl: 'https://via.placeholder.com/150',
    ),
    DefaultSong(
      title: 'Song Title',
      artist: 'Song Artist',
      album: 'Song Album',
      imageUrl: 'https://via.placeholder.com/150',
    ),
    DefaultSong(
      title: 'Song Title',
      artist: 'Song Artist',
      album: 'Song Album',
      imageUrl: 'https://via.placeholder.com/150',
    ),
  ];

  @override
  void songBook() {}
}
