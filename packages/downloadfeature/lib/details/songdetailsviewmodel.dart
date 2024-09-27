part of '../downloadfeature.dart';

abstract class SongDetailsViewModel extends ChangeNotifier {
  ValueNotifier<SongDownloadState> get songDownloadStateNotifier;
  String get imageUrl;
  String get songTitle;
  String get songArtist;
  String get songLanguage;
  bool get isOffVocal;
  bool get videoHasLyrics;
  String get songLyrics;

  void updateSongTitle(String text);
  void updateSongArtist(String text);
  void updateSongLanguage(String text);
  void toggleOffVocal(bool value);
  void toggleVideoHasLyrics(bool value);
  void updateSongLyrics(String text);
  void download(bool andReserve);
}

class DefaultSongDetailsViewModel extends SongDetailsViewModel {
  final DownloadUseCase downloadUseCase;
  final IdentifiedSongDetails identifiedSongDetails;

  DefaultSongDetailsViewModel({
    required this.downloadUseCase,
    required this.identifiedSongDetails,
  }) {
    imageUrl = identifiedSongDetails.imageUrl;
    songTitle = identifiedSongDetails.songTitle;
    songArtist = identifiedSongDetails.songArtist;
    songLanguage = identifiedSongDetails.songLanguage;
    isOffVocal = identifiedSongDetails.isOffVocal;
    videoHasLyrics = identifiedSongDetails.videoHasLyrics;
    songLyrics = identifiedSongDetails.songLyrics;
  }

  @override
  ValueNotifier<SongDownloadState> songDownloadStateNotifier =
      ValueNotifier(SongDownloadState.idle());

  @override
  String imageUrl = '';

  @override
  String songTitle = '';

  @override
  String songArtist = '';

  @override
  String songLanguage = '';

  @override
  bool isOffVocal = false;

  @override
  bool videoHasLyrics = false;

  @override
  String songLyrics = '';

  @override
  void updateSongTitle(String text) {
    songTitle = text;
  }

  @override
  void updateSongArtist(String text) {
    songArtist = text;
  }

  @override
  void updateSongLanguage(String text) {
    songLanguage = text;
  }

  @override
  void toggleOffVocal(bool? value) {
    isOffVocal = value ?? false;
    notifyListeners();
  }

  @override
  void toggleVideoHasLyrics(bool? value) {
    videoHasLyrics = value ?? false;
    notifyListeners();
  }

  @override
  void updateSongLyrics(String text) {
    songLyrics = text;
  }

  @override
  void download(bool andReserve) async {
    songDownloadStateNotifier.value = SongDownloadState.loading();

    final details = identifiedSongDetails.copyWith(
      songTitle: songTitle,
      songArtist: songArtist,
      songLanguage: songLanguage,
      isOffVocal: isOffVocal,
      videoHasLyrics: videoHasLyrics,
      songLyrics: songLyrics,
    );
    final result =
        await downloadUseCase.downloadSong(details, reserve: andReserve).run();

    result.fold(
      (exception) {
        songDownloadStateNotifier.value = SongDownloadState.failure(exception);
      },
      (_) {
        songDownloadStateNotifier.value = SongDownloadState.success();
      },
    );
  }
}
