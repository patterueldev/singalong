library adminfeature;

import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:common/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fpdart/fpdart.dart' show TaskEither, Unit, unit;
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:textfield_tags/textfield_tags.dart';

part 'admincoordinator.dart';
part 'adminlocalizations.dart';
part 'common/sliderdata.dart';
part 'signin/signin_screen.dart';
part 'signin/signin_viewmodel.dart';
part 'signin/signin_usecase.dart';
part 'sessionmanager/session_manager_screen.dart';
part 'sessionmanager/session_manager_viewmodel.dart';
part 'sessionmanager/load_rooms_usecase.dart';
part 'sessionmanager/rooms_repository.dart';
part 'sessionmanager/load_rooms_parameters.dart';
part 'sessionmanager/connect_with_room_parameters.dart';
part 'playermanager/playermanagerwidget.dart';
part 'playermanager/playermanagerviewmodel.dart';
part 'player_control_panel/player_control_panel_widget.dart';
part 'player_control_panel/player_control_panel_viewmodel.dart';
part 'player_control_panel/controlpanelsocketrepository.dart';
part 'player_control_panel/authorize_connection_usecase.dart';
part 'player_control_panel/player_control_panel_state.dart';
part 'create_room/create_room_dialog.dart';
part 'create_room/create_room_viewmodel.dart';
part 'reserved_panel/reserved_panel_widget.dart';
part 'reserved_panel/reserved_panel_viewmodel.dart';
part 'songview/song_editor_viewmodel.dart';
part 'songview/songviewstate.dart';
part 'songview/song_editor_view.dart';
part 'songview/songrepository.dart';
part 'participants_panel/participants_panel_widget.dart';
part 'participants_panel/participants_panel_viewmodel.dart';

class AdminFeatureUIProvider {
  AdminFeatureUIProvider();

  Widget buildSignInScreen(
    BuildContext context, {
    String username = '',
    String password = '',
  }) =>
      ChangeNotifierProvider<SignInViewModel>(
        create: (context) => DefaultSignInViewModel(
          connectRepository: context.read(),
          persistenceRepository: context.read(),
          singalongConfiguration: context.read(),
          username: username,
          password: password,
        ),
        child: SignInScreen(
          coordinator: context.read(),
          localizations: context.read(),
        ),
      );

  Widget buildSessionManagerScreen(BuildContext context) =>
      ChangeNotifierProvider<SessionManagerViewModel>(
        create: (context) => DefaultSessionManagerViewModel(
          roomsRepository: context.read(),
          connectRepository: context.read(),
          persistenceRepository: context.read(),
        ),
        child: SessionManagerScreen(
          coordinator: context.read(),
        ),
      );

  Widget buildPlayerControlPanel(Room room) =>
      ChangeNotifierProvider<PlayerControlPanelViewModel>(
        create: (context) => DefaultPlayerControlPanelViewModel(
          connectRepository: context.read(),
          controlPanelRepository: context.read(),
          room: room,
        ),
        child: const PlayerControlPanelWidget(),
      );

  Widget buildPlayerManagerDialog(Room room) =>
      ChangeNotifierProvider<PlayerSelectorViewModel>(
        create: (context) => DefaultPlayerSelectorViewModel(
          socketRepository: context.read(),
          room: room,
        ),
        child: PlayerSelectorDialogWidget(),
      );

  Widget buildReservedPanel() => ChangeNotifierProvider<ReservedPanelViewModel>(
        create: (context) => DefaultReservedPanelViewModel(
          reservedSongListSocketRepository: context.read(),
        ),
        child: const ReservedPanelWidget(),
      );

  Widget buildSongEditorPanel(BuildContext context, String songId) =>
      ChangeNotifierProvider<SongEditorViewModel>(
        create: (context) => DefaultSongViewModel(
          songRepository: context.read(),
          songId: songId,
        ),
        child: SongEditorView(
          localizations: context.read(),
          coordinator: context.read(),
        ),
      );

  Widget buildParticipantsPanelWidget(BuildContext context) =>
      ChangeNotifierProvider<ParticipantsPanelViewModel>(
        create: (context) => DefaultParticipantsPanelViewModel(
          userParticipantRepository: context.read(),
        ),
        child: const ParticipantsPanelWidget(),
      );
}
