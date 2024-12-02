part of 'songbookfeature.dart';

abstract class SongBookLocalizations implements GenericLocalizations {
  LocalizedString get songBookScreenTitle;
  LocalizedString get searchHint;
  LocalizedString get search;
  LocalizedString get download;
  LocalizedString get emptySongBook;

  LocalizedString get isUrlPromptTitle;
  LocalizedString get isUrlPromptMessage;

  LocalizedString get continueSearchButtonText;
  LocalizedString get continueIdentifyButtonText;

  LocalizedString songNotFound(String query);
  LocalizedString urlDetected(String url);

  LocalizedString get lyricsLabelText;
  LocalizedString get noLyricsText;
}
