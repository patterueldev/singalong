library downloadfeature;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

part 'downloadassets.dart';
part 'downloadlocalizations.dart';
part 'downloadflowcontroller.dart';
part 'manual/identifysongview.dart';
part 'search/songsearchview.dart';
part 'details/songdetailsview.dart';
part 'details/songdetailsviewmodel.dart';

class DownloadFeatureProvider {
  DownloadFeatureProvider();

  Widget buildIdentifyUrlView({
    required BuildContext context,
    required DownloadFlowController flow,
    required DownloadLocalizations localizations,
  }) =>
      ChangeNotifierProvider<IdentifySongViewModel>(
        create: (context) => DefaultIdentifySongViewModel(),
        child: IdentifySongView(
          flow: flow,
          localizations: localizations,
        ),
      );

  Widget buildSongDetailsView({
    required BuildContext context,
    required DownloadLocalizations localizations,
  }) =>
      ChangeNotifierProvider<SongDetailsViewModel>(
        create: (context) => DefaultSongDetailsViewModel(),
        child: SongDetailsView(
          localizations: localizations,
        ),
      );
}

class DownloadException extends GenericException {}
