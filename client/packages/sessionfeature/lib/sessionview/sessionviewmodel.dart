part of '../sessionfeature.dart';

abstract class SessionViewModel extends ChangeNotifier {
  ValueNotifier<SessionViewState> stateNotifier =
      ValueNotifier(SessionViewState.initial());
  ValueNotifier<List<ReservedSongItem>> songListNotifier = ValueNotifier([]);
  ValueNotifier<PromptModel?> promptNotifier = ValueNotifier(null);
  ValueNotifier<ReservedSongItem?> songDetailsNotifier = ValueNotifier(null);
  ValueNotifier<bool> isSongBookOpenNotifier = ValueNotifier(false);

  void setupSession();
  void dismissSong(ReservedSongItem song);
  void reorderSongList(oldIndex, newIndex);
  void openSongDetails(ReservedSongItem song);
  void openSongBook();
  void disconnect();
}

class DefaultSessionViewModel extends SessionViewModel {
  final ListenToSongListUpdatesUseCase listenToSongListUpdatesUseCase;
  final ConnectRepository connectRepository;
  final SessionLocalizations localizations;

  DefaultSessionViewModel({
    required this.listenToSongListUpdatesUseCase,
    required this.connectRepository,
    required this.localizations,
    List<ReservedSongItem>? songList,
  }) {
    if (songList != null) {
      songListNotifier.value = songList;
    }
  }

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

    connectRepository.connectSocket();
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
    promptNotifier.value = PromptModel.standard(
      localizations,
      title: title,
      message: message,
      actionText: actionText,
      action: () => completer.complete(true),
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
