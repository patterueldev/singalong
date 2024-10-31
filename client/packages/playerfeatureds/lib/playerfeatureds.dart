library playerfeatureds;

import 'package:flutter/foundation.dart';
import 'package:playerfeature/playerfeature.dart';
import 'package:provider/provider.dart';
import 'package:singalong_api_client/singalong_api_client.dart';

part 'connectrepositoryds.dart';
part 'currentsongrepositoryds.dart';

class PlayerFeatureDSProvider {
  final providers = MultiProvider(
    providers: [
      Provider<ConnectRepository>(
        create: (context) => ConnectRepositoryDS(
          client: context.read(),
          sessionManager: context.read(),
        ),
      ),
      Provider<CurrentSongRepository>(
        create: (context) => CurrentSongRepositoryDS(
          client: context.read(),
          sessionManager: context.read(),
        ),
      ),
      Provider<ReservedSongListRepository>(
        create: (context) => ReservedSongListRepositoryDS(
          apiClient: context.read(),
          sessionManager: context.read(),
        ),
      ),
      Provider(
        create: (context) => PlayerFeatureBuilder(
          connectRepository: context.read(),
          currentSongRepository: context.read(),
          reservedSongListRepository: context.read(),
        ),
      ),
    ],
  );
}

class ReservedSongListRepositoryDS implements ReservedSongListRepository {
  final SingalongAPIClient apiClient;
  final APISessionManager sessionManager;

  ReservedSongListRepositoryDS({
    required this.apiClient,
    required this.sessionManager,
  });

  @override
  Stream<List<ReservedSongItem>> listenToSongListUpdates() async* {
    await for (final apiReservedSongs in apiClient.listenReservedSongs()) {
      final reservedSongList = apiReservedSongs
          .map(
            (apiReservedSong) => ReservedSongItem(
              title: apiReservedSong.title,
              artist: apiReservedSong.artist,
              reservedBy: apiReservedSong.reservingUser,
              thumbnailURL:
                  apiClient.resourceURL(apiReservedSong.thumbnailPath),
            ),
          )
          .toList();
      debugPrint("Reserved Song List: $reservedSongList");
      yield reservedSongList;
    }
  }
}
