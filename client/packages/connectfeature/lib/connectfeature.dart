library connectfeature;

import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show Either, TaskEither, Unit, unit;
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

part 'connectscene/connectview.dart';
part 'connectscene/connectviewstate.dart';
part 'connectscene/connectviewmodel.dart';
part 'connectscene/establishconnectionusecase.dart';
part 'connectlocalizations.dart';
part 'connectflowcontroller.dart';
part 'connectscene/connectexception.dart';
part 'connectassets.dart';

class ConnectFeatureBuilder {
  ConnectFeatureBuilder();

  Widget buildConnectView(
    BuildContext context, {
    String? name,
    String? roomId,
  }) =>
      ChangeNotifierProvider<ConnectViewModel>(
        create: (context) => DefaultConnectViewModel(
          connectRepository: context.read(),
          persistenceService: context.read(),
          name: name,
          roomId: roomId,
        ),
        child: ConnectView(
          flow: context.read(),
          localizations: context.read(),
          assets: context.read(),
        ),
      );
}
