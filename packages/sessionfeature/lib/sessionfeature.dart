library sessionfeature;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

part 'sessionview.dart';
part 'songitem.dart';
part 'sessionviewmodel.dart';
part 'sessionviewstate.dart';
part 'listentosonglistupdatesusecase.dart';

class SessionFeatureProvider {
  SessionFeatureProvider();

  final List<SingleChildStatelessWidget> providers = [
    Provider<ListenToSongListUpdatesUseCase>(
      create: (context) => DefaultListenToSongListUpdatesUseCase(),
    ),
  ];

  Widget buildSessionView({SessionViewModel? viewModel}) => Builder(
        builder: (context) {
          return SessionView(
            viewModel: viewModel ??
                DefaultSessionViewModel(
                  listenToSongListUpdatesUseCase: context.read(),
                ),
          );
        },
      );
}
