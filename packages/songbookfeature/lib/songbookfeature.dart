library songbookfeature;

import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:skeletonizer/skeletonizer.dart';

part 'songbookview.dart';
part 'songbookviewmodel.dart';
part 'songitem.dart';
part 'songbookviewstate.dart';
part 'songbooklocalizations.dart';

class SongBookFeatureProvider {
  const SongBookFeatureProvider();

  Widget buildSongBookView({
    required BuildContext context,
    required SongBookLocalizations localizations,
  }) =>
      SongBookView(
        viewModel: DefaultSongBookViewModel(),
        localizations: localizations,
      );
}
