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
    return song.toSongDetails(configuration);
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

  @override
  Future<void> deleteSongDetails(String songId) async {
    await api.deleteSong(songId);
  }

  @override
  Future<SongDetails> enhanceSongDetails(SongDetails song) async {
    final enhancedSong = await api.enhanceSongDetails(song.id);
    return SongDetails(
      id: enhancedSong.id,
      source: enhancedSong.source,
      title: enhancedSong.title,
      artist: enhancedSong.artist,
      language: enhancedSong.language,
      isOffVocal: enhancedSong.isOffVocal,
      videoHasLyrics: enhancedSong.videoHasLyrics,
      duration: enhancedSong.duration,
      genres: enhancedSong.genres,
      tags: enhancedSong.tags,
      metadata: enhancedSong.metadata,
      thumbnailURL:
          configuration.buildResourceURL(enhancedSong.thumbnailPath).toString(),
      currentPlaying: enhancedSong.currentPlaying,
      lyrics: enhancedSong.lyrics,
      addedBy: enhancedSong.addedBy,
      addedAtSession: enhancedSong.addedAtSession,
      lastUpdatedBy: enhancedSong.lastUpdatedBy,
      isCorrupted: enhancedSong.isCorrupted,
    );
  }
}
