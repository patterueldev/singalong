part of '../downloadfeature.dart';

abstract class SongIdentifierRepository {
  Future<IdentifiedSongDetails> identifySongUrl(String url);
  Future<void> saveSong(IdentifiedSongDetails details, {required bool reserve});
  Future<List<DownloadableItem>> searchDownloadableSong(String query);
}
