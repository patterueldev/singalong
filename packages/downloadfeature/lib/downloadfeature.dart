library downloadfeature;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show TaskEither;
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

part 'downloadassets.dart';
part 'downloadexception.dart';
part 'downloadlocalizations.dart';
part 'downloadflowcontroller.dart';
part 'shared/identifiedsongdetails.dart';
part 'manual/identifysongview.dart';
part 'manual/identifysongviewmodel.dart';
part 'manual/identifysongusecase.dart';
part 'manual/submissionresult.dart';
part 'search/songsearchview.dart';
part 'details/songdetailsview.dart';
part 'details/songdetailsviewmodel.dart';

class DownloadFeatureProvider {
  DownloadFeatureProvider();

  final providers = MultiProvider(providers: [
    Provider<IdentifySongUrlUseCase>(
      create: (context) => DefaultIdentifySongUrlUseCase(),
    ),
  ]);

  Widget buildIdentifyUrlView({
    required BuildContext context,
    required DownloadAssets assets,
    required DownloadFlowController flow,
    required DownloadLocalizations localizations,
  }) =>
      ChangeNotifierProvider<IdentifySongViewModel>(
        create: (context) => DefaultIdentifySongViewModel(
          identifySongUrlUseCase: context.read(),
        ),
        child: IdentifySongView(
          assets: assets,
          flow: flow,
          localizations: localizations,
        ),
      );

  Widget buildSongDetailsView({
    required BuildContext context,
    required IdentifiedSongDetails identifiedSongDetails,
    required DownloadLocalizations localizations,
  }) =>
      ChangeNotifierProvider<SongDetailsViewModel>(
        create: (context) => DefaultSongDetailsViewModel(
          identifiedSongDetails: identifiedSongDetails,
        ),
        child: SongDetailsView(localizations: localizations),
      );
}
