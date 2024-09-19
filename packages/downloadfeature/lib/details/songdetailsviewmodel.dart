part of '../downloadfeature.dart';

abstract class SongDetailsViewModel extends ChangeNotifier {
  ValueNotifier<bool> get isLoadingNotifier => ValueNotifier(false);
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
  final IdentifiedSongDetails identifiedSongDetails;

  DefaultSongDetailsViewModel({
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
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);

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
    debugPrint('Download and reserve: $andReserve');
    isLoadingNotifier.value = true;

    await Future.delayed(const Duration(seconds: 2));

    isLoadingNotifier.value = false;
  }
}
