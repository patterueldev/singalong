library sessionfeature;

import 'package:flutter/material.dart';

part 'sessionview.dart';
part 'sessionviewmodel.dart';

class SessionFeatureProvider {
  Widget buildSessionView({SessionViewModel? viewModel}) => SessionView(
        viewModel: viewModel ?? DefaultSessionViewModel(),
      );
}
