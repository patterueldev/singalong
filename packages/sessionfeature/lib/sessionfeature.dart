library sessionfeature;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared/shared.dart';

part 'sessionview/sessionview.dart';
part 'entities/reservedsongitem.dart';
part 'sessionview/sessionviewmodel.dart';
part 'sessionview/sessionviewstate.dart';
part 'usecases/listentosonglistupdatesusecase.dart';
part 'sessionnavigationcoordinator.dart';
part 'sessionlocalizations.dart';

class SessionFeatureProvider {
  SessionFeatureProvider();

  final providers = MultiProvider(
    providers: [
      Provider<ListenToSongListUpdatesUseCase>(
        create: (context) => DefaultListenToSongListUpdatesUseCase(),
      ),
    ],
  );

  Widget buildSessionView({
    required BuildContext context,
    required SessionNavigationCoordinator coordinator,
    required SessionLocalizations localizations,
  }) =>
      SessionView(
        viewModel: DefaultSessionViewModel(
          listenToSongListUpdatesUseCase: context.read(),
          localizations: context.read(),
        ),
        localizations: localizations,
        coordinator: coordinator,
      );
}
