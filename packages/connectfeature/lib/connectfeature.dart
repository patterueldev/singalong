library connectfeature;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

part 'connectview.dart';
part 'connectviewmodel.dart';

class ConnectFeatureProvider {
  Widget buildConnectView({ConnectViewModel? viewModel}) => ConnectView(
        viewModel: viewModel ?? DefaultConnectViewModel(),
      );
}
