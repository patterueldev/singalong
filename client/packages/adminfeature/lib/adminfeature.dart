library adminfeature;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:common/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fpdart/fpdart.dart' show TaskEither, Unit, unit;
import 'package:provider/provider.dart';
import 'package:core/core.dart';

part 'admincoordinator.dart';
part 'common/sliderdata.dart';
part 'signin/signin_screen.dart';
part 'signin/signin_viewmodel.dart';
part 'sessionmanager/session_manager_screen.dart';
part 'sessionmanager/session_manager_viewmodel.dart';
part 'player_control_panel/player_control_panel_widget.dart';
part 'player_control_panel/player_control_panel_viewmodel.dart';
part 'player_control_panel/controlpanelsocketrepository.dart';
part 'player_control_panel/authorize_connection_usecase.dart';
part 'player_control_panel/player_control_panel_state.dart';

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
          username: username,
          password: password,
        ),
        child: SignInScreen(
          coordinator: context.read(),
        ),
      );

  Widget buildSessionManagerScreen() =>
      ChangeNotifierProvider<SessionManagerViewModel>(
        create: (context) => DefaultSessionManagerViewModel(
          persistenceRepository: context.read(),
        ),
        child: const SessionManagerScreen(),
      );

  Widget buildPlayerControlPanel() =>
      ChangeNotifierProvider<PlayerControlPanelViewModel>(
        create: (context) => DefaultPlayerControlPanelViewModel(
          connectRepository: context.read(),
          controlPanelRepository: context.read(),
        ),
        child: const PlayerControlPanelWidget(),
      );
}
