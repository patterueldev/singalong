part of '../playerfeature.dart';

class NextSongUseCase {
  final CurrentSongRepository currentSongRepository;

  NextSongUseCase({
    required this.currentSongRepository,
  });

  Future<void> call() async {
    await currentSongRepository.nextSong();
  }
}
