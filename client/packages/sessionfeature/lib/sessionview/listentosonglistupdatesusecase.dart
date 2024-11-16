part of '../sessionfeature.dart';

abstract class ReservedSongListSocketRepository {
  StreamController<List<ReservedSongItem>> get reservedSongListStreamController;
  void requestReservedSongList();
}
