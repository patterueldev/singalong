part of '../sessionfeature.dart';

abstract class SessionViewModel {
  ValueNotifier<SessionViewState> get stateNotifier;
  ValueNotifier<List<ReservedSongItem>> get songListNotifier;
  ValueNotifier<PromptModel?> get promptNotifier;
  ValueNotifier<ReservedSongItem?> get songDetailsNotifier;
  ValueNotifier<bool> get isSongBookOpenNotifier;

  void setupSession();
  void dismissSong(ReservedSongItem song);
  void reorderSongList(oldIndex, newIndex);
  void openSongDetails(ReservedSongItem song);
  void openSongBook();
  void disconnect();
}

class DefaultSessionViewModel extends SessionViewModel {
  final ListenToSongListUpdatesUseCase listenToSongListUpdatesUseCase;
  final SessionLocalizations localizations;

  DefaultSessionViewModel({
    required this.listenToSongListUpdatesUseCase,
    required this.localizations,
    List<ReservedSongItem>? songList,
  }) {
    if (songList != null) {
      songListNotifier.value = songList;
    }
  }

  @override
  ValueNotifier<SessionViewState> stateNotifier =
      ValueNotifier(SessionViewState.initial());
  @override
  ValueNotifier<List<ReservedSongItem>> songListNotifier = ValueNotifier([]);
  @override
  ValueNotifier<PromptModel?> promptNotifier = ValueNotifier(null);
  @override
  ValueNotifier<ReservedSongItem?> songDetailsNotifier = ValueNotifier(null);
  @override
  ValueNotifier<bool> isSongBookOpenNotifier = ValueNotifier(false);

  @override
  void setupSession() async {
    // this class will essentially "prepare" the session
    // maybe processing some stuff at first
    // then setup an active observer to listen to changes for the song list
    stateNotifier.value = SessionViewState.loading();
    await Future.delayed(const Duration(seconds: 2));
    // if there's an error, we can throw an exception; use Failure state instead of Loading
    stateNotifier.value = SessionViewState.loaded();
    // then start listening to changes

    listenToSongListUpdatesUseCase().listen((songList) {
      songListNotifier.value = songList;
    });
  }

  @override
  void dismissSong(ReservedSongItem song) async {
    final completer = Completer<bool>();
    LocalizedString title;
    LocalizedString message;
    LocalizedString actionText;
    if (song.currentPlaying) {
      title = localizations.skipSongTitle;
      message = localizations.skipSongMessage;
      actionText = localizations.skipSongActionText;
    } else {
      title = localizations.cancelSongTitle;
      message = localizations.cancelSongMessage;
      actionText = localizations.cancelSongActionText;
    }
    promptNotifier.value = PromptModel(
      title: title,
      message: message,
      actionText: actionText,
      onAction: () {
        completer.complete(true);
      },
    );

    final result = await completer.future;
    promptNotifier.value = null;

    if (!result) {
      return;
    }
  }

  @override
  void reorderSongList(oldIndex, newIndex) {}

  @override
  void openSongDetails(ReservedSongItem song) {}

  @override
  void openSongBook() {
    isSongBookOpenNotifier.value = true;
  }

  @override
  void disconnect() {
    // dispose of the observer
    stateNotifier.value = SessionViewState.disconnected();
  }
}
