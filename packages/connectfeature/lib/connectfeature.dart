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

class ConnectFeatureProvider {
  ConnectFeatureProvider();

  final providers = MultiProvider(
    providers: [
      ProxyProvider<ConnectLocalizations, ConnectUseCase>(
        update: (context, localizable, previous) => DefaultConnectUseCase(
          localizable: localizable,
        ),
      ),
    ],
  );

  Widget buildConnectView({
    required BuildContext context,
    required ConnectNavigationCoordinator coordinator,
    required ConnectLocalizations localizations,
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
      );
}
