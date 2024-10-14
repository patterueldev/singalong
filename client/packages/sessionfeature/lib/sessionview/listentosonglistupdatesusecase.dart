part of '../sessionfeature.dart';

class ListenToSongListUpdatesUseCase {
  final ReservedSongListRepository reservedSongListRepository;

  ListenToSongListUpdatesUseCase({
    required this.reservedSongListRepository,
  });

  Stream<List<ReservedSongItem>> execute() {
    return reservedSongListRepository.listenToSongListUpdates();
  }
}

abstract class ReservedSongListRepository {
  Stream<List<ReservedSongItem>> listenToSongListUpdates();
}
