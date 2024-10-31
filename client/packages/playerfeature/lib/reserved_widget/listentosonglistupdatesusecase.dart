part of '../playerfeature.dart';

class ListenToSongListUpdatesUseCase {
  final ReservedSongListRepository reservedSongListRepository;

  ListenToSongListUpdatesUseCase({
    required this.reservedSongListRepository,
  });

  Stream<List<ReservedSongItem>> call() {
    return reservedSongListRepository.listenToSongListUpdates();
  }
}

abstract class ReservedSongListRepository {
  Stream<List<ReservedSongItem>> listenToSongListUpdates();
}
