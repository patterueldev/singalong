part of '../sessionfeature.dart';

abstract class ReservedSongListSocketRepository {
  StreamController<List<ReservedSongItem>> reservedSongListStreamController();
}
