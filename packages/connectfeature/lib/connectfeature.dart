library connectfeature;

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show TaskEither, Unit, unit;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

part 'connectview.dart';
part 'connectviewstate.dart';
part 'connectviewmodel.dart';
part 'connectusecase.dart';
part 'connectlocalizations.dart';
part 'connectnavigationdelegate.dart';

class ConnectFeatureProvider {
  ConnectFeatureProvider();

  final providers = MultiProvider(
    providers: [
      ProxyProvider<ConnectLocalizable, ConnectUseCase>(
        update: (context, localizable, previous) => DefaultConnectUseCase(
          localizable: localizable,
        ),
      ),
    ],
  );

  Widget buildConnectView({
    required BuildContext context,
    required ConnectNavigationCoordinator coordinator,
    required ConnectLocalizable localizable,
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
        localizable: localizable,
      );
}
