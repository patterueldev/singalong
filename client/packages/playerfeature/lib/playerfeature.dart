library playerfeature;

import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show TaskEither, Unit, unit;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart';
import 'package:video_player/video_player.dart'
    show VideoPlayerController, VideoPlayer;
import "package:video_controls/video_controls.dart" show VideoController;

part 'connect/connectrepository.dart';
part 'socket/socketrepository.dart';
part 'player_scene/player_view.dart';
part 'player_scene/player_viewmodel.dart';
part 'player_scene/player_viewstate.dart';
part 'player_scene/listentocurrentsongupdatesusecase.dart';
part 'player_scene/authorize_connection_usecase.dart';
part 'player_scene/next_song_usecase.dart';
part 'current_song/currentsong.dart';
part 'current_song/currentsongrepository.dart';
part 'reserved_widget/reserved_widget.dart';
part 'reserved_widget/reserved_viewmodel.dart';
part 'reserved_widget/listentosonglistupdatesusecase.dart';
part 'connectivity_panel_widget/connectivity_panel_widget.dart';

class PlayerFeatureBuilder {
  final ConnectRepository connectRepository;
  final SocketRepository socketRepository;
  final CurrentSongRepository currentSongRepository;
  final ReservedSongListRepository reservedSongListRepository;

  PlayerFeatureBuilder({
    required this.connectRepository,
    required this.socketRepository,
    required this.currentSongRepository,
    required this.reservedSongListRepository,
  });

  late final connectUseCase =
      AuthorizeConnectionUseCase(connectRepository: connectRepository);
  late final nextSongUseCase =
      NextSongUseCase(currentSongRepository: currentSongRepository);
  late final listenToCurrentSongUpdatesUseCase =
      ListenToCurrentSongUpdatesUseCase(
          currentSongRepository: currentSongRepository);
  late final listenToSongListUpdatesUseCase = ListenToSongListUpdatesUseCase(
      reservedSongListRepository: reservedSongListRepository);

  Widget buildPlayerView() => MultiProvider(
        providers: [
          ChangeNotifierProvider<ReservedViewModel>(
            create: (context) => DefaultReservedViewModel(
              listenToSongListUpdatesUseCase: listenToSongListUpdatesUseCase,
            ),
          ),
          ChangeNotifierProvider<PlayerViewModel>(
            create: (context) => DefaultPlayerViewModel(
              connectUseCase: connectUseCase,
              nextSongUseCase: nextSongUseCase,
              listenToCurrentSongUpdatesUseCase:
                  listenToCurrentSongUpdatesUseCase,
              connectRepository: context.read(),
              socketRepository: context.read(),
              reservedViewModel: context.read(),
            ),
          ),
        ],
        child: const PlayerView(),
      );
}
