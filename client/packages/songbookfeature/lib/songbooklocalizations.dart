part of 'songbookfeature.dart';

abstract class SongBookLocalizations implements GenericLocalizations {
  LocalizedString get songBookScreenTitle;
  LocalizedString get searchHint;
  LocalizedString get download;
  LocalizedString get emptySongBook;

  LocalizedString get isUrlPromptTitle;
  // like: This seems to be a URL. Do you want to identify the song?
  LocalizedString get isUrlPromptMessage;

  LocalizedString get continueSearchButtonText;
  LocalizedString get continueIdentifyButtonText;

  LocalizedString songNotFound(String query);
  LocalizedString urlDetected(String url);
}
