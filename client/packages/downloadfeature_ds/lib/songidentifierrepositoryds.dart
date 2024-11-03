part of 'downloadfeature_ds.dart';

class DefaultSongIdentifierRepository implements SongIdentifierRepository {
  final SingalongAPIClient apiClient;

  const DefaultSongIdentifierRepository({
    required this.apiClient,
  });

  @override
  Future<IdentifiedSongDetails> identifySongUrl(String url) async {
    try {
      final result = await apiClient.identifySong(
        APIIdentifySongParameters(url: url),
      );
      return IdentifiedSongDetails(
        id: result.id,
        source: result.source,
        imageUrl: result.imageUrl,
        songTitle: result.songTitle,
        songArtist: result.songArtist,
        songLanguage: result.songLanguage,
        isOffVocal: result.isOffVocal,
        videoHasLyrics: result.videoHasLyrics,
        songLyrics: result.songLyrics,
        alreadyExists: result.alreadyExists,
      );
    } catch (e, st) {
      debugPrint("Error: $e");
      rethrow;
    }
  }

  @override
  Future<void> saveSong(IdentifiedSongDetails details,
      {required bool reserve}) {
    // TODO: implement downloadSong
    throw UnimplementedError();
  }
}
