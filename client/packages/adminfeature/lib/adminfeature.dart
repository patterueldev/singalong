library adminfeature;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show TaskEither, Unit, unit;
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

part 'common/sliderdata.dart';
part 'connect/connectrepository.dart';
part 'player_control_panel/player_control_panel_widget.dart';
part 'player_control_panel/player_control_panel_viewmodel.dart';
part 'player_control_panel/controlpanelrepository.dart';
part 'player_control_panel/authorize_connection_usecase.dart';
part 'player_control_panel/player_control_panel_state.dart';

class AdminFeatureProvider {
  final ConnectRepository connectRepository;
  final ControlPanelRepository controlPanelRepository;

  AdminFeatureProvider({
    required this.connectRepository,
    required this.controlPanelRepository,
  });

  late final AuthorizeConnectionUseCase _authorizeConnectionUseCase =
      AuthorizeConnectionUseCase(
    connectRepository: connectRepository,
  );

  Widget buildPlayerControlPanel() =>
      ChangeNotifierProvider<PlayerControlPanelViewModel>(
        create: (_) => DefaultPlayerControlPanelViewModel(
          authorizeConnectionUseCase: _authorizeConnectionUseCase,
          connectRepository: connectRepository,
          controlPanelRepository: controlPanelRepository,
        ),
        child: const PlayerControlPanelWidget(),
      );
}
