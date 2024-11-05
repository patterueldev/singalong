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
  LocalizedString get alreadyExists;

  LocalizedString get emptySongTitle;
  LocalizedString get emptySongArtist;
  LocalizedString get emptySongLanguage;

  LocalizedString get searchByURL;
  LocalizedString get enterSearchKeyword;

  LocalizedString itemNotFound(String item);
}
