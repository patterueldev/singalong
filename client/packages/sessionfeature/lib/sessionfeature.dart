library sessionfeature;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import 'package:common/common.dart';

part 'sessionview/sessionview.dart';
part 'entities/reservedsongitem.dart';
part 'sessionview/sessionviewmodel.dart';
part 'sessionview/sessionviewstate.dart';
part 'sessionview/listentosonglistupdatesusecase.dart';
part 'songview/songview.dart';
part 'songview/songviewmodel.dart';
part 'songview/songviewstate.dart';
part 'songview/songmodel.dart';
part 'sessionnavigationcoordinator.dart';
part 'sessionlocalizations.dart';

class SessionFeatureBuilder {
  final SessionFlowCoordinator coordinator;
  final SessionLocalizations localizations;
  final ReservedSongListRepository reservedSongListRepository;

  SessionFeatureBuilder({
    required this.coordinator,
    required this.localizations,
    required this.reservedSongListRepository,
  });

  late final _listenToSongListUpdatesUseCase = ListenToSongListUpdatesUseCase(
      reservedSongListRepository: reservedSongListRepository);

  Widget buildSessionView(BuildContext context) =>
      ChangeNotifierProvider<SessionViewModel>(
        create: (context) => DefaultSessionViewModel(
          listenToSongListUpdatesUseCase: _listenToSongListUpdatesUseCase,
          connectRepository: context.read(),
          localizations: localizations,
        ),
        child: SessionView(
          localizations: localizations,
          flow: coordinator,
        ),
      );
}
