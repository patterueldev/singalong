part of 'downloadfeature_ds.dart';

class DefaultSongIdentifierRepository implements SongIdentifierRepository {
  final SingalongAPI api;
  final SingalongConfiguration configuration;

  const DefaultSongIdentifierRepository({
    required this.api,
    required this.configuration,
  });

  @override
  Future<IdentifiedSongDetails> identifySongUrl(String url) async {
    try {
      final result = await api.identifySong(
        APIIdentifySongParameters(url: url),
      );
      return IdentifiedSongDetails(
        id: result.id,
        source: result.source,
        imageUrl: configuration.buildProxyURL(result.imageUrl).toString(),
        songTitle: result.songTitle,
        songArtist: result.songArtist,
        songLanguage: result.songLanguage,
        isOffVocal: result.isOffVocal,
        videoHasLyrics: result.videoHasLyrics,
        songLyrics: result.songLyrics,
        lengthSeconds: result.lengthSeconds,
        metadata: result.metadata,
        genres: result.genres,
        tags: result.tags,
        alreadyExists: result.alreadyExists,
      );
    } catch (e, st) {
      debugPrint("Error: $e");
      rethrow;
    }
  }

  @override
  Future<void> saveSong(IdentifiedSongDetails details,
      {required bool reserve}) async {
    try {
      final apiDetails = APIIdentifiedSongDetails(
        id: details.id,
        source: details.source,
        imageUrl: details.imageUrl,
        songTitle: details.songTitle,
        songArtist: details.songArtist,
        songLanguage: details.songLanguage,
        isOffVocal: details.isOffVocal,
        videoHasLyrics: details.videoHasLyrics,
        songLyrics: details.songLyrics,
        lengthSeconds: details.lengthSeconds,
        metadata: details.metadata,
        genres: details.genres,
        tags: details.tags,
        alreadyExists: details.alreadyExists,
      );
      final parameters = APISaveSongParameters(
        song: apiDetails,
        thenReserve: reserve,
      );
      await api.saveSong(parameters);
    } catch (e, st) {
      debugPrint("Error: $e");
      debugPrint("Stacktrace: $st");
      rethrow;
    }
  }

  @override
  Future<List<DownloadableItem>> searchDownloadableSong(String query) async {
    try {
      final result = await api.searchDownloadables(
        APISearchDownloadablesParameters(keyword: query),
      );
      return result
          .map(
            (e) => DownloadableItem(
              sourceUrl: e.url,
              title: e.name,
              artist: e.author.name,
              thumbnailURL: configuration.buildProxyURL(e.thumbnail).toString(),
              duration: e.duration,
              alreadyDownloaded: e.alreadyExists,
            ),
          )
          .toList();
    } catch (e, st) {
      debugPrint("Error: $e");
      rethrow;
    }
  }
}
