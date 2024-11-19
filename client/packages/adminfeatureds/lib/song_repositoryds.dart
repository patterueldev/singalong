part of 'adminfeatureds.dart';

class SongRepositoryDS implements SongRepository {
  final SingalongAPI api;
  final SingalongConfiguration configuration;

  SongRepositoryDS({
    required this.api,
    required this.configuration,
  });

  @override
  Future<SongDetails> getSongDetails(String songId) async {
    final song =
        await api.loadSongDetails(APILoadSongDetailsParameters(songId: songId));
    return SongDetails(
      id: song.id,
      source: song.source,
      title: song.title,
      artist: song.artist,
      language: song.language,
      isOffVocal: song.isOffVocal,
      videoHasLyrics: song.videoHasLyrics,
      duration: song.duration,
      genres: song.genres,
      tags: song.tags,
      metadata: song.metadata,
      thumbnailURL:
          configuration.buildResourceURL(song.thumbnailPath).toString(),
      currentPlaying: song.currentPlaying,
      lyrics: song.lyrics,
      addedBy: song.addedBy,
      addedAtSession: song.addedAtSession,
      lastUpdatedBy: song.lastUpdatedBy,
      isCorrupted: song.isCorrupted,
    );
  }

  @override
  Future<void> saveSongDetails(SongDetails song) async {
    final parameters = APIUpdateSongParameters(
      songId: song.id,
      title: song.title,
      artist: song.artist,
      language: song.language,
      isOffVocal: song.isOffVocal,
      videoHasLyrics: song.videoHasLyrics,
      songLyrics: song.lyrics ?? '',
      metadata: song.metadata,
      genres: song.genres,
      tags: song.tags,
    );
    final result = await api.updateSongDetails(parameters);
    debugPrint('saveSongDetails: $result');
  }
}
