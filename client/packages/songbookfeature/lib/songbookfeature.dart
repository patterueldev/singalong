library songbookfeature;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show TaskEither;
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import 'package:skeletonizer/skeletonizer.dart';

part 'songbookview/songbookview.dart';
part 'songbookview/songbookviewmodel.dart';
part 'songitem.dart';
part 'songbookviewstate.dart';
part 'songbooklocalizations.dart';
part 'songbooknavigationcoordinator.dart';
part 'songbookassets.dart';
part 'fetchsongsusecase.dart';

class SongBookFeatureProvider {
  final SongBookFlowCoordinator coordinator;
  final SongBookLocalizations localizations;
  final SongBookAssets assets;

  SongBookFeatureProvider({
    required this.coordinator,
    required this.localizations,
    required this.assets,
  });

  late final _fetchSongsUseCase = DefaultFetchSongsUseCase();

  Widget buildSongBookView({required BuildContext context}) => SongBookView(
        viewModel: DefaultSongBookViewModel(
          fetchSongsUseCase: _fetchSongsUseCase,
        ),
        navigationCoordinator: coordinator,
        localizations: localizations,
        assets: assets,
      );
}
