library songbookfeature;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show TaskEither, Unit, unit;
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:skeletonizer/skeletonizer.dart';

part 'songbookview/songbookview.dart';
part 'songbookview/songbookviewmodel.dart';
part 'song/songrepository.dart';
part 'songbookview/songbookviewstate.dart';
part 'songbooklocalizations.dart';
part 'songbooknavigationcoordinator.dart';
part 'songbookassets.dart';
part 'songbookview/fetchsongsusecase.dart';
part 'songbookview/reservesongusecase.dart';
part 'songdetailsview/songview.dart';
part 'songdetailsview/songviewmodel.dart';
part 'songdetailsview/songviewstate.dart';

class SongBookFeatureProvider {
  final SongBookFlowCoordinator coordinator;
  final SongBookLocalizations localizations;
  final SongBookAssets assets;
  final SongRepository songRepository;

  SongBookFeatureProvider({
    required this.coordinator,
    required this.localizations,
    required this.assets,
    required this.songRepository,
  });

  late final _fetchSongsUseCase =
      DefaultFetchSongsUseCase(songRepository: songRepository);

  late final _reserveSongUseCase =
      DefaultReserveSongUseCase(songRepository: songRepository);

  Widget buildSongBookView({
    required BuildContext context,
    bool canGoBack = true,
    String? roomId,
  }) =>
      ChangeNotifierProvider<SongBookViewModel>(
        create: (context) => DefaultSongBookViewModel(
            fetchSongsUseCase: _fetchSongsUseCase,
            reserveSongUseCase: _reserveSongUseCase,
            localizations: localizations,
            roomId: roomId),
        child: SongBookView(
          navigationCoordinator: coordinator,
          localizations: localizations,
          assets: assets,
          canGoBack: canGoBack,
        ),
      );

  Widget buildSongDetailsView({
    required BuildContext context,
    required String songId,
  }) =>
      ChangeNotifierProvider<SongViewModel>(
        create: (context) => DefaultSongViewModel(
          songRepository: context.read(),
          songId: songId,
        ),
        child: SongView(
          localizations: context.read(),
        ),
      );
}
