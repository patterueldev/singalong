part of '../adminfeature.dart';

abstract class SongRepository {
  Future<SongDetails> getSongDetails(String songId);
  Future<void> saveSongDetails(SongDetails song);
}
