import 'package:adminfeature/adminfeature.dart';
import 'package:adminfeatureds/adminfeatureds.dart';
import 'package:commonds/commonds.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:singalong_api_client/singalong_api_client.dart';
import 'package:songbookfeature/songbookfeature.dart';
import 'package:songbookfeatureds/songbookfeatureds.dart';

import '_main.dart';

void main() {
  final singalongAPIClientProvider = SingalongAPIClientProvider();
  final commonProvider = CommonProvider();
  final adminFeatureDSProvider = AdminFeatureDSProvider();
  final songBookFeatureDSProvider = SongBookFeatureDSProvider();
  final coordinator = AppCoordinator();
  final appLocalizations = DefaultAppLocalizations();
  final assets = DefaultAppAssets();

  runApp(MultiProvider(
    providers: [
      Provider.value(value: singalongAPIClientProvider),
      Provider<SingalongConfiguration>.value(value: APIConfiguration()),
      Provider<AdminCoordinator>.value(value: coordinator),
      Provider<AdminLocalizations>.value(value: appLocalizations),
      Provider<SongBookFlowCoordinator>.value(value: coordinator),
      Provider<SongBookLocalizations>.value(value: appLocalizations),
      Provider<SongBookAssets>.value(value: assets),
      singalongAPIClientProvider.providers,
      commonProvider.providers,
      adminFeatureDSProvider.providers,
      songBookFeatureDSProvider.providers,
    ],
    child: ChangeNotifierProvider<AdminAppViewModel>(
      create: (context) => DefaultAdminAppViewModel(
        connectRepository: context.read(),
      ),
      child: const AdminApp(),
    ),
  ));
}
