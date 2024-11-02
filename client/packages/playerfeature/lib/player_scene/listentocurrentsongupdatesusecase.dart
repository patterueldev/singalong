part of '../playerfeature.dart';

class ListenToCurrentSongUpdatesUseCase {
  final CurrentSongRepository currentSongRepository;

  ListenToCurrentSongUpdatesUseCase({
    required this.currentSongRepository,
  });

  Stream<CurrentSong?> call() {
    return currentSongRepository.listenToCurrentSongUpdates();
  }
}
