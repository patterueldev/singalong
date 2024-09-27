part of '../downloadfeature.dart';

abstract class SongIdentifierRepository {
  Future<IdentifiedSongDetails> identifySongUrl(String url);
}
