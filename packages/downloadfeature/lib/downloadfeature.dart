library downloadfeature;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

part 'downloadassets.dart';
part 'downloadlocalizations.dart';
part 'downloadnavigationcoordinator.dart';
part 'manual/songurlview.dart';
part 'search/songsearchview.dart';
part 'details/songdetailsview.dart';
part 'details/songdetailsviewmodel.dart';

class DownloadFeatureProvider {
  DownloadFeatureProvider();

  Widget buildSongDetailsView({
    required BuildContext context,
  }) =>
      ChangeNotifierProvider<SongDetailsViewModel>(
        create: (context) => DefaultSongDetailsViewModel(),
        child: SongDetailsView(
          localizations: TemplateDownloadLocalizations(),
        ),
      );
}
