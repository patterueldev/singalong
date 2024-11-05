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
        lengthSeconds: result.lengthSeconds,
        metadata: result.metadata,
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
        alreadyExists: details.alreadyExists,
      );
      final parameters = APISaveSongParameters(
        song: apiDetails,
        thenReserve: reserve,
      );
      final result = await apiClient.saveSong(parameters);
      debugPrint("Save song result: $result");

      // if (reserve) {
      //   await apiClient
      //       .reserveSong(APIReserveSongParameters(songId: result.id));
      //   debugPrint("Song reserved");
      // }
    } catch (e, st) {
      debugPrint("Error: $e");
      debugPrint("Stacktrace: $st");
      rethrow;
    }
  }

  @override
  Future<List<DownloadableItem>> searchDownloadableSong(String query) async {
    try {
      final result = await apiClient.searchDownloadables(
        APISearchDownloadablesParameters(keyword: query),
      );
      return result
          .map((e) => DownloadableItem(
                sourceUrl: e.url,
                title: e.name,
                artist: e.author.name,
                thumbnailURL: e.thumbnail,
                duration: e.duration,
              ))
          .toList();
    } catch (e, st) {
      debugPrint("Error: $e");
      rethrow;
    }
  }
}
