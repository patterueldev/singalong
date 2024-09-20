library downloadfeature;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show TaskEither, Unit, unit;
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

part 'downloadassets.dart';
part 'downloadexception.dart';
part 'downloadlocalizations.dart';
part 'downloadflowcontroller.dart';
part 'shared/identifiedsongdetails.dart';
part 'shared/identifysongusecase.dart';
part 'manual/identifysongview.dart';
part 'manual/identifysongviewmodel.dart';
part 'manual/identifysubmissionstate.dart';
part 'search/songsearchview.dart';
part 'search/downloadablesearchviewmodel.dart';
part 'details/songdetailsview.dart';
part 'details/songdetailsviewmodel.dart';
part 'details/songdetailsdownloadstate.dart';
part 'details/downloadusecase.dart';

class DownloadFeatureProvider {
  DownloadFeatureProvider();

  final providers = MultiProvider(providers: [
    Provider<IdentifySongUrlUseCase>(
      create: (context) => DefaultIdentifySongUrlUseCase(),
    ),
    Provider<DownloadUseCase>(
      create: (context) => DefaultDownloadUseCase(),
    ),
  ]);

  Widget buildIdentifyUrlView({
    required BuildContext context,
    required DownloadAssets assets,
  }) =>
      ChangeNotifierProvider<IdentifySongViewModel>(
        create: (context) => DefaultIdentifySongViewModel(
          identifySongUrlUseCase: context.read(),
        ),
        child: IdentifySongView(
          assets: assets,
          flow: context.read(),
          localizations: context.read(),
        ),
      );

  Widget buildSongSearchView() =>
      ChangeNotifierProvider<DownloadableSearchViewModel>(
        create: (context) => DefaultDownloadableSearchViewModel(),
        child: DownloadableSongSearchView(),
      );

  Widget buildSongDetailsView({
    required BuildContext context,
    required IdentifiedSongDetails identifiedSongDetails,
  }) =>
      ChangeNotifierProvider<SongDetailsViewModel>(
        create: (context) => DefaultSongDetailsViewModel(
          downloadUseCase: context.read(),
          identifiedSongDetails: identifiedSongDetails,
        ),
        child: SongDetailsView(
          flow: context.read(),
          localizations: context.read(),
        ),
      );
}
