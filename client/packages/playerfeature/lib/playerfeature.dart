library playerfeature;

import 'dart:async';
import 'dart:ffi';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show TaskEither, Unit, unit;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:core/core.dart';
import 'package:video_player/video_player.dart'
    show VideoPlayerController, VideoPlayer;
import "package:video_controls/video_controls.dart" show VideoController;

part 'socket/socketrepository.dart';
part 'player_scene/player_view.dart';
part 'player_scene/player_viewmodel.dart';
part 'player_scene/player_viewstate.dart';
part 'player_scene/authorize_connection_usecase.dart';
part 'reserved_widget/reserved_widget.dart';
part 'reserved_widget/reserved_viewmodel.dart';
part 'reserved_widget/reservedsonglistsocketrepository.dart';
part 'connectivity_panel_widget/connectivity_panel_widget.dart';
part 'participants_panel/participants_panel_widget.dart';
part 'participants_panel/participants_panel_viewmodel.dart';

class PlayerFeatureUIBuilder {
  PlayerFeatureUIBuilder();

  Widget buildPlayerView() => MultiProvider(
        providers: [
          ChangeNotifierProvider<ReservedViewModel>(
            create: (context) => DefaultReservedViewModel(
              reservedSongListSocketRepository: context.read(),
            ),
          ),
          ChangeNotifierProvider<PlayerViewModel>(
            create: (context) => DefaultPlayerViewModel(
              connectRepository: context.read(),
              playerSocketRepository: context.read(),
              persistenceRepository: context.read(),
              reservedViewModel: context.read(),
              configuration: context.read(),
            ),
          ),
        ],
        child: const PlayerView(),
      );

  Widget buildParticipantsPanelWidget(
    BuildContext context, {
    required String host,
    required String roomId,
  }) =>
      ChangeNotifierProvider<ParticipantsPanelViewModel>(
        create: (context) => DefaultParticipantsPanelViewModel(
          userParticipantRepository: context.read(),
        ),
        child: ParticipantsPanelWidget(
          host: host,
          roomId: roomId,
        ),
      );
}
