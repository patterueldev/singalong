part of 'adminfeature.dart';

abstract class AdminLocalizations extends GenericLocalizations {
  LocalizedString get clearButtonText => LocalizedString(
        (context) => "Clear",
      );

  LocalizedString get editServerHostDialogTitle => LocalizedString(
        (context) => "Customize Server Host",
      );
  LocalizedString get serverHostPlaceholderText => LocalizedString(
        (context) => "Enter the server host",
      );
  LocalizedString get saveButtonText => LocalizedString(
        (context) => "Save",
      );

  LocalizedString get lyricsLabelText => LocalizedString(
        (context) => "Lyrics",
      );
  LocalizedString get noLyricsText => LocalizedString(
        (context) => "No lyrics available",
      );

  LocalizedString get songTitlePlaceholderText => LocalizedString(
        (context) => "Title",
      );
  LocalizedString get songArtistPlaceholderText => LocalizedString(
        (context) => "Artist",
      );
  LocalizedString get songLanguagePlaceholderText => LocalizedString(
        (context) => "Language",
      );
  LocalizedString get isOffVocalText => LocalizedString(
        (context) => "Off Vocal",
      );
  LocalizedString get hasLyricsText => LocalizedString(
        (context) => "Video Has Lyrics",
      );
  LocalizedString get lyricsPlaceholderText => LocalizedString(
        (context) => "Lyrics",
      );
}
