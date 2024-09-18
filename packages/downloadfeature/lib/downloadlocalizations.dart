part of 'downloadfeature.dart';

abstract class DownloadLocalizations {
  LocalizedString get songDetailsScreenTitleText;
  LocalizedString get songTitlePlaceholderText;
  LocalizedString get songArtistPlaceholderText;
  LocalizedString get songLanguagePlaceholderText;
  LocalizedString get isOffVocalText;
  LocalizedString get hasLyricsText;
  LocalizedString get lyricsPlaceholderText;

  LocalizedString get downloadOnlyText;
  LocalizedString get downloadAndReserveText;
}

class TemplateDownloadLocalizations implements DownloadLocalizations {
  @override
  LocalizedString get songDetailsScreenTitleText =>
      LocalizedString((context) => "Song Details");

  @override
  LocalizedString get songTitlePlaceholderText =>
      LocalizedString((context) => "Song Title");

  @override
  LocalizedString get songArtistPlaceholderText =>
      LocalizedString((context) => "Song Artist");
  @override
  LocalizedString get songLanguagePlaceholderText =>
      LocalizedString((context) => "Song Language");

  @override
  LocalizedString get isOffVocalText =>
      LocalizedString((context) => "Is Off Vocal");

  @override
  LocalizedString get hasLyricsText =>
      LocalizedString((context) => "Has Lyrics");

  @override
  LocalizedString get lyricsPlaceholderText =>
      LocalizedString((context) => "Lyrics");

  @override
  LocalizedString get downloadOnlyText =>
      LocalizedString((context) => "Download Only");

  @override
  LocalizedString get downloadAndReserveText =>
      LocalizedString((context) => "Download & Reserve");
}
