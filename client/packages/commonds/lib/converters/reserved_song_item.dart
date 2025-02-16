part of '../commonds.dart';

extension APIReservedSongExtension on APIReservedSong {
  ReservedSongItem toReservedSongItem(SingalongConfiguration configuration) {
    return ReservedSongItem(
        id: id,
        songId: songId,
        title: title,
        artist: artist,
        thumbnailURL: configuration.buildResourceURL(thumbnailPath).toString(),
        reservingUser: reservingUser,
        order: order,
        currentPlaying: currentPlaying,
        finishedPlaying: false //TODO: Implement this
        );
  }
}
