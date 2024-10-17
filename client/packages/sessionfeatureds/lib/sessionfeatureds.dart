library sessionfeatureds;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:singalong_api_client/singalong_api_client.dart';

class SessionFeatureDSProvider {
  final providers = MultiProvider(providers: [
    Provider<ReservedSongListRepository>(
      create: (context) => ReservedSongListRepositoryDS(
        apiClient: context.read(),
      ),
    ),
    Provider(
      create: (context) => SessionFeatureBuilder(
        localizations: context.read(),
        coordinator: context.read(),
        reservedSongListRepository: context.read(),
      ),
    ),
  ]);
}

class ReservedSongListRepositoryDS implements ReservedSongListRepository {
  final SingalongAPIClient apiClient;

  ReservedSongListRepositoryDS({
    required this.apiClient,
  });

  @override
  Stream<List<ReservedSongItem>> listenToSongListUpdates() async* {
    await for (final apiSongs in apiClient.listenReservedSongs()) {
      debugPrint("API Songs: $apiSongs");
      final reservedSongs = apiSongs
          .map((apiSong) => ReservedSongItem(
                id: apiSong.id,
                songId: apiSong.songId,
                title: apiSong.title,
                artist: apiSong.artist,
                thumbnailURL: apiClient.resourceURL(apiSong.thumbnailPath),
                reservingUser: apiSong.reservingUser,
                currentPlaying: apiSong.currentPlaying,
              ))
          .toList();
      final imageURLs = reservedSongs.map((e) => e.thumbnailURL).join("\n");
      debugPrint("Image URLs:\n$imageURLs");
      yield reservedSongs;
    }
  }
}
