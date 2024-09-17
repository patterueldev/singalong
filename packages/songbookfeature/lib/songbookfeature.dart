library songbookfeature;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import 'package:skeletonizer/skeletonizer.dart';

part 'songbookview.dart';
part 'songbookviewmodel.dart';
part 'songitem.dart';
part 'songbookviewstate.dart';
part 'songbooklocalizations.dart';
part 'songbooknavigationcoordinator.dart';

class SongBookFeatureProvider {
  SongBookFeatureProvider();

  final providers = MultiProvider(
    providers: [
      Provider<String>(
        create: (context) => "",
      )
      // Provider<FetchSongsUseCase>(
      //   create: (context) => DefaultFetchSongsUseCase(),
      // ),
    ],
  );

  Widget buildSongBookView({
    required BuildContext context,
    required SongBookNavigationCoordinator coordinator,
    required SongBookLocalizations localizations,
  }) =>
      SongBookView(
        viewModel: DefaultSongBookViewModel(),
        navigationCoordinator: coordinator,
        localizations: localizations,
      );
}
