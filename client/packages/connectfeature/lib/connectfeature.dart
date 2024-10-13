library connectfeature;

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show TaskEither, Unit, unit;
import 'package:shared/shared.dart';

part 'connectscene/connectview.dart';
part 'connectscene/connectviewstate.dart';
part 'connectscene/connectviewmodel.dart';
part 'connectscene/establishconnectionusecase.dart';
part 'connectscene/connectrepository.dart';
part 'connectlocalizations.dart';
part 'connectflowcontroller.dart';
part 'connectscene/connectexception.dart';
part 'connectassets.dart';

class ConnectFeature {
  final ConnectLocalizations localizations;
  final ConnectAssets assets;
  final ConnectFlowController coordinator;
  final ConnectRepository connectRepository;

  ConnectFeature({
    required this.localizations,
    required this.assets,
    required this.coordinator,
    required this.connectRepository,
  });

  late final EstablishConnectionUseCase establishConnectionUseCase =
      DefaultEstablishConnectionUseCase(connectRepository: connectRepository);
  // final providers = MultiProvider(
  //   providers: [
  //     Provider<EstablishConnectionUseCase>(
  //       create: (context) => DefaultEstablishConnectionUseCase(),
  //     ),
  //   ],
  // );

  Widget buildConnectView({
    String name = '',
    String roomId = '',
  }) =>
      ConnectView(
        viewModel: DefaultConnectViewModel(
          connectUseCase: establishConnectionUseCase,
          name: name,
          roomId: roomId,
        ),
        flow: coordinator,
        localizations: localizations,
        assets: assets,
      );
}
