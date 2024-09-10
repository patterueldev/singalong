library connectfeature;

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show TaskEither, Unit, unit;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

part 'connectview.dart';
part 'connectviewstate.dart';
part 'connectviewmodel.dart';

class ConnectFeatureProvider {
  ConnectFeatureProvider();

  final List<SingleChildStatelessWidget> providers = [
    Provider<ConnectUseCase>(
      create: (context) => DefaultConnectUseCase(),
    ),
  ];

  Widget buildConnectView({required ConnectViewModel viewModel}) =>
      ConnectView(viewModel: viewModel);
}

abstract class ConnectViewLocalizations {
  String connect(BuildContext context);
  String clear(BuildContext context);
  String name(BuildContext context);
  String sessionId(BuildContext context);
}

class DefaultConnectViewLocalizations implements ConnectViewLocalizations {
  const DefaultConnectViewLocalizations();

  @override
  String connect(BuildContext context) => 'Connect';

  @override
  String clear(BuildContext context) => 'Clear';

  @override
  String name(BuildContext context) => 'Name';

  @override
  String sessionId(BuildContext context) => 'Session ID';
}
