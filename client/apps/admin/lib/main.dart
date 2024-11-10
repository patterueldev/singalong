import 'package:adminfeature/adminfeature.dart';
import 'package:adminfeatureds/adminfeatureds.dart';
import 'package:commonds/commonds.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:singalong_api_client/singalong_api_client.dart';

import '_main.dart';

void main() {
  final singalongAPIClientProvider = SingalongAPIClientProvider();
  final commonProvider = CommonProvider();
  final adminFeatureDSProvider = AdminFeatureDSProvider();
  final coordinator = AppCoordinator();
  runApp(MultiProvider(
    providers: [
      Provider<SingalongConfiguration>.value(value: APIConfiguration()),
      Provider<AdminCoordinator>.value(value: coordinator),
      singalongAPIClientProvider.providers,
      commonProvider.providers,
      adminFeatureDSProvider.providers,
    ],
    child: ChangeNotifierProvider<AdminAppViewModel>(
      create: (context) => DefaultAdminAppViewModel(
        connectRepository: context.read(),
      ),
      child: const AdminApp(),
    ),
  ));
}

class AppCoordinator extends AdminCoordinator {
  @override
  void onSignInSuccess(BuildContext context) {
    debugPrint('onSignInSuccess');
    context.read<AdminAppViewModel>().checkAuthentication();
  }
}
