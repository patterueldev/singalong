library songbookfeature;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show TaskEither;
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import 'package:skeletonizer/skeletonizer.dart';

part 'songbookview.dart';
part 'songbookviewmodel.dart';
part 'songitem.dart';
part 'songbookviewstate.dart';
part 'songbooklocalizations.dart';
part 'songbooknavigationcoordinator.dart';
part 'songbookassets.dart';
part 'fetchsongsusecase.dart';

class SongBookFeatureProvider {
  SongBookFeatureProvider();

  final providers = MultiProvider(
    providers: [
      Provider<FetchSongsUseCase>(
        create: (context) => DefaultFetchSongsUseCase(),
      ),
    ],
  );

  Widget buildSongBookView({
    required BuildContext context,
    required SongBookNavigationCoordinator coordinator,
    required SongBookLocalizations localizations,
    required SongBookAssets assets,
  }) =>
      SongBookView(
        viewModel: DefaultSongBookViewModel(
          fetchSongsUseCase: context.read(),
        ),
        navigationCoordinator: coordinator,
        localizations: localizations,
        assets: assets,
      );
}
