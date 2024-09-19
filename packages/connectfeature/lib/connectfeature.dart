library connectfeature;

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show TaskEither, Unit, unit;
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

class ConnectFeatureProvider {
  ConnectFeatureProvider();

  final providers = MultiProvider(
    providers: [
      Provider<EstablishConnectionUseCase>(
        create: (context) => DefaultEstablishConnectionUseCase(),
      ),
    ],
  );

  Widget buildConnectView({
    required BuildContext context,
    required ConnectFlowController coordinator,
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
        flow: coordinator,
        localizations: localizations,
        assets: assets,
      );
}
