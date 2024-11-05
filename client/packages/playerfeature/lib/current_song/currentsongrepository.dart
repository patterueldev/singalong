part of '../playerfeature.dart';

abstract class CurrentSongRepository {
  Stream<CurrentSong?> listenToCurrentSongUpdates();
  Future<void> nextSong();
}
