library downloadfeature;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' show TaskEither, Unit, unit;
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';
import 'package:skeletonizer/skeletonizer.dart';

part 'downloadassets.dart';
part 'downloadexception.dart';
part 'downloadlocalizations.dart';
part 'downloadflowcontroller.dart';
part 'shared/identifiedsongdetails.dart';
part 'shared/identifysongusecase.dart';
part 'shared/songidentifierrepository.dart';
part 'manual/identifysongview.dart';
part 'manual/identifysongviewmodel.dart';
part 'manual/identifysubmissionstate.dart';
part 'search/searchdownloadableview.dart';
part 'search/searchdownloadableviewmodel.dart';
part 'search/searchdownloadableviewstate.dart';
part 'search/searchdownloadableusecase.dart';
part 'search/downloadableitem.dart';
part 'details/songdetailsview.dart';
part 'details/songdetailsviewmodel.dart';
part 'details/songdetailsdownloadstate.dart';
part 'details/downloadusecase.dart';

class DownloadFeatureProvider {
  final DownloadFlowCoordinator coordinator;
  final DownloadLocalizations localizations;
  final DownloadAssets assets;
  final SongIdentifierRepository songIdentifierRepository;

  DownloadFeatureProvider({
    required this.coordinator,
    required this.localizations,
    required this.assets,
    required this.songIdentifierRepository,
  });

  late final _identifySongUseCase = DefaultIdentifySongUrlUseCase(
    songIdentifierRepository: songIdentifierRepository,
  );

  late final _downloadUseCase = DefaultDownloadUseCase(
    identifiedSongRepository: songIdentifierRepository,
  );

  late final _searchDownloadableSongUseCase =
      DefaultSearchDownloadableSongUseCase(
    identifiedSongRepository: songIdentifierRepository,
  );

  Widget buildIdentifyUrlView({required BuildContext context, String? url}) =>
      ChangeNotifierProvider<IdentifySongViewModel>(
        create: (context) => DefaultIdentifySongViewModel(
            identifySongUrlUseCase: _identifySongUseCase, songUrl: url ?? ''),
        child: IdentifySongView(
          assets: assets,
          flow: coordinator,
          localizations: localizations,
        ),
      );

  Widget buildSearchDownloadableView({String? query}) =>
      ChangeNotifierProvider<SearchDownloadableViewModel>(
        create: (context) => DefaultSearchDownloadableViewModel(
            searchDownloadableSongUseCase: _searchDownloadableSongUseCase,
            identifySongUrlUseCase: _identifySongUseCase,
            searchQuery: query ?? ''),
        child: SearchDownloadableView(
          coordinator: coordinator,
          localizations: localizations,
          assets: assets,
        ),
      );

  Widget buildSongDetailsView({
    required BuildContext context,
    required IdentifiedSongDetails identifiedSongDetails,
  }) =>
      ChangeNotifierProvider<SongDetailsViewModel>(
        create: (context) => DefaultSongDetailsViewModel(
          downloadUseCase: _downloadUseCase,
          identifiedSongDetails: identifiedSongDetails,
        ),
        child: SongDetailsView(
          flow: coordinator,
          localizations: localizations,
        ),
      );
}
