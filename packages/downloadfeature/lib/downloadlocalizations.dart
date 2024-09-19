part of 'downloadfeature.dart';

abstract class DownloadLocalizations implements GenericLocalizations {
  LocalizedString get songDetailsScreenTitleText;
  LocalizedString get songTitlePlaceholderText;
  LocalizedString get songArtistPlaceholderText;
  LocalizedString get songLanguagePlaceholderText;
  LocalizedString get isOffVocalText;
  LocalizedString get hasLyricsText;
  LocalizedString get lyricsPlaceholderText;

  LocalizedString get downloadOnlyText;
  LocalizedString get downloadAndReserveText;

  LocalizedString get identifySongScreenTitleText;
  LocalizedString get identifySongUrlPlaceholderText;
  LocalizedString get identifySongSubmitButtonText;

  LocalizedString get emptyUrl;
  LocalizedString get invalidUrl;
  LocalizedString get unableToIdentifySong;
}

class TemplateDownloadLocalizations implements DownloadLocalizations {
  @override
  LocalizedString get unknownError =>
      LocalizedString((context) => "An unknown error occurred");
  @override
  LocalizedString unhandled(String message) =>
      LocalizedString((context) => "An unhandled error occurred: $message");

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

  @override
  LocalizedString get identifySongScreenTitleText =>
      LocalizedString((context) => "Identify Song");

  @override
  LocalizedString get identifySongUrlPlaceholderText =>
      LocalizedString((context) => "Identify Song URL");

  @override
  LocalizedString get identifySongSubmitButtonText =>
      LocalizedString((context) => "Identify");

  @override
  LocalizedString get emptyUrl =>
      LocalizedString((context) => "The URL cannot be empty");

  @override
  LocalizedString get invalidUrl =>
      LocalizedString((context) => "The URL is invalid");

  @override
  LocalizedString get unableToIdentifySong =>
      LocalizedString((context) => "Unable to identify the song");
}
