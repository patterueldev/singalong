library connectfeature;

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show TaskEither, Unit, unit;
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

part 'connectview.dart';
part 'connectviewstate.dart';
part 'connectviewmodel.dart';
part 'connectusecase.dart';
part 'connectlocalizations.dart';
part 'connectnavigationcoordinator.dart';
part 'connectexception.dart';
part 'connectassets.dart';

class ConnectFeatureProvider {
  ConnectFeatureProvider();

  final providers = MultiProvider(
    providers: [
      Provider<ConnectUseCase>(
        create: (context) => DefaultConnectUseCase(),
      ),
    ],
  );

  Widget buildConnectView({
    required BuildContext context,
    required ConnectNavigationCoordinator coordinator,
    required ConnectLocalizations localizations,
    required ConnectAssets assets,
    String name = '',
    String sessionId = '',
  }) =>
      ConnectView(
        viewModel: DefaultConnectViewModel(
          connectUseCase: context.read(),
          name: name,
          sessionId: sessionId,
        ),
        coordinator: coordinator,
        localizations: localizations,
        assets: assets,
      );
}
