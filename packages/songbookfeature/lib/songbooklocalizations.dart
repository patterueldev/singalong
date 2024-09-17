part of 'songbookfeature.dart';

abstract class SongBookLocalizations implements GenericLocalizations {
  LocalizedString get songBookScreenTitle;
  LocalizedString get searchHint;
  LocalizedString get download;
  LocalizedString get emptySongBook;
  LocalizedString songNotFound(String query);
}
