library playerfeature;

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show TaskEither, Unit, unit;
import 'package:shared/shared.dart';
import 'package:video_player/video_player.dart';

part 'player_scene/player_view.dart';
part 'player_scene/player_viewmodel.dart';
part 'player_scene/player_viewstate.dart';
part 'player_scene/listentocurrentsongupdatesusecase.dart';
part 'current_song/currentsong.dart';
part 'current_song/currentsongrepository.dart';

class PlayerFeatureBuilder {
  final ConnectRepository connectRepository;
  final CurrentSongRepository currentSongRepository;

  PlayerFeatureBuilder({
    required this.connectRepository,
    required this.currentSongRepository,
  });

  late final connectUseCase =
      ConnectUseCase(connectRepository: connectRepository);
  late final listenToCurrentSongUpdatesUseCase =
      ListenToCurrentSongUpdatesUseCase(
          currentSongRepository: currentSongRepository);

  Widget buildPlayerView() => PlayerView(
        viewModel: DefaultPlayerViewModel(
          connectUseCase: connectUseCase,
          listenToCurrentSongUpdatesUseCase: listenToCurrentSongUpdatesUseCase,
        ),
      );
}
