part of '../playerfeature.dart';

abstract class ReservedSongListSocketRepository {
  StreamController<List<ReservedSongItem>> get reservedSongsStreamController;
}
