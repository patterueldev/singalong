part of '../commonds.dart';

extension APISongDetailsExtension on APISongDetails {
  SongDetails toSongDetails(SingalongConfiguration configuration) {
    final song = this;
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
}
