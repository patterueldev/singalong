library playerfeatureds;

import 'package:flutter/foundation.dart';
import 'package:playerfeature/playerfeature.dart';
import 'package:provider/provider.dart';
import 'package:singalong_api_client/singalong_api_client.dart';

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
      Provider(
        create: (context) => PlayerFeatureBuilder(
          connectRepository: context.read(),
          currentSongRepository: context.read(),
        ),
      ),
    ],
  );
}

class ConnectRepositoryDS implements ConnectRepository {
  final SingalongAPIClient client;
  final APISessionManager sessionManager;

  ConnectRepositoryDS({
    required this.client,
    required this.sessionManager,
  });

  @override
  Future<ConnectResponse> connect(ConnectParameters parameters) async {
    final result = await client.connect(parameters.toAPI());
    return result.fromAPI();
  }

  @override
  void provideAccessToken(String accessToken) {
    sessionManager.setAccessToken(accessToken);
  }
}

extension ConnectParametersMapper on ConnectParameters {
  APIConnectParameters toAPI() {
    return APIConnectParameters(
      username: username,
      roomId: roomId,
      clientType: clientType,
    );
  }
}

extension APIConnectResponseMapper on APIConnectResponseData {
  ConnectResponse fromAPI() {
    return ConnectResponse(
      requiresUserPasscode: requiresUserPasscode,
      requiresRoomPasscode: requiresRoomPasscode,
      accessToken: accessToken,
    );
  }
}

class CurrentSongRepositoryDS implements CurrentSongRepository {
  final SingalongAPIClient client;
  final APISessionManager sessionManager;

  CurrentSongRepositoryDS({
    required this.client,
    required this.sessionManager,
  });

  @override
  Stream<CurrentSong?> listenToCurrentSongUpdates() async* {
    await for (final apiCurrentSong in client.listenCurrentSong()) {
      debugPrint("API Current Song: $apiCurrentSong");
      if (apiCurrentSong == null) {
        yield null;
        continue;
      }
      final currentSong = CurrentSong(
        id: apiCurrentSong.id,
        title: apiCurrentSong.title,
        artist: apiCurrentSong.artist,
        thumbnailURL: client.resourceURL(apiCurrentSong.thumbnailPath),
        reservingUser: apiCurrentSong.reservingUser,
        videoURL: client.resourceURL(apiCurrentSong.videoPath),
      );
      debugPrint("Current Song: $currentSong");
      yield currentSong;
    }
  }
}
