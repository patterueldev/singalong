library connectfeatureds;

import 'package:connectfeature/connectfeature.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:singalong_api_client/singalong_api_client.dart';

class ConnectFeatureDSProvider {
  final providers = MultiProvider(providers: [
    Provider(
      create: (context) => ConnectFeatureBuilder(),
    ),
  ]);
}
