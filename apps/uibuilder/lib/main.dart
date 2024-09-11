import 'package:connectfeature/connectfeature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part 'applocalizations.dart';
part 'appcoordinator.dart';
part 'ui/navigatoritem.dart';
part 'ui/previewerviewmodel.dart';
part 'ui/previewerview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final connectFeatureProvider = ConnectFeatureProvider();
    final sessionFeatureProvider = SessionFeatureProvider();
    final localizations = DefaultAppLocalizations();
    final appCoordinator = AppCoordinator(
      connectFeatureProvider: connectFeatureProvider,
      sessionFeatureProvider: sessionFeatureProvider,
    );
    return MultiProvider(
      providers: [
        Provider<AppCoordinator>.value(value: appCoordinator),
        Provider<ConnectNavigationCoordinator>.value(value: appCoordinator),
        Provider<SessionNavigationCoordinator>.value(value: appCoordinator),
        Provider<ConnectLocalizations>.value(value: localizations),
        Provider<SessionLocalizations>.value(value: localizations),
        connectFeatureProvider.providers,
        sessionFeatureProvider.providers,
      ],
      child: MaterialApp(
        title: 'Singalong UI Builder',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.tealAccent),
          useMaterial3: true,
        ),
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangeNotifierProvider<PreviewerViewModel>(
          create: (ctx) => DefaultPreviewerViewModel(
            connectFeatureProvider: connectFeatureProvider,
            sessionFeatureProvider: sessionFeatureProvider,
          ),
          child: const PreviewerView(),
        ),
      ),
    );
  }
}
