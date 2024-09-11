library sessionfeature;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

part 'sessionview.dart';
part 'reservedsongitem.dart';
part 'sessionviewmodel.dart';
part 'sessionviewstate.dart';
part 'listentosonglistupdatesusecase.dart';
part 'promptmodel.dart';

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
  }) =>
      SessionView(
        viewModel: DefaultSessionViewModel(
          listenToSongListUpdatesUseCase: context.read(),
        ),
        coordinator: coordinator,
      );
}
