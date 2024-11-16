library sessionfeature;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
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

class SessionFeatureUIBuilder {
  SessionFeatureUIBuilder();

  Widget buildSessionView(BuildContext context) =>
      ChangeNotifierProvider<SessionViewModel>(
        create: (context) => DefaultSessionViewModel(
          reservedSongListSocketRepository: context.read(),
          connectRepository: context.read(),
          persistenceRepository: context.read(),
          localizations: context.read(),
        ),
        child: SessionView(
          localizations: context.read(),
          flow: context.read(),
        ),
      );
}
