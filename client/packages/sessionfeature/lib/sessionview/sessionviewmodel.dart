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
  final ReservedSongListSocketRepository reservedSongListSocketRepository;
  final ConnectRepository connectRepository;
  final SessionLocalizations localizations;

  DefaultSessionViewModel({
    required this.reservedSongListSocketRepository,
    required this.connectRepository,
    required this.localizations,
    List<ReservedSongItem>? songList,
  }) {
    if (songList != null) {
      songListNotifier.value = songList;
    }
  }

  StreamController<List<ReservedSongItem>>? streamController;

  @override
  void setupSession() async {
    try {
      debugPrint('Setting up session');
      stateNotifier.value = SessionViewState.loading();

      debugPrint('Opening socket');
      streamController =
          reservedSongListSocketRepository.reservedSongListStreamController();
      debugPrint('Listening to stream');
      streamController?.stream.listen((songList) {
        songListNotifier.value = songList;
      });

      debugPrint('Connecting to socket');

      connectRepository.connectSocket();
      stateNotifier.value = SessionViewState.loaded();

      debugPrint('Session setup complete; State: ${stateNotifier.value}');
    } catch (e, st) {
      debugPrint('Error setting up session: $e');
      debugPrintStack(stackTrace: st);
      stateNotifier.value = SessionViewState.failure(e.toString());
    }
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

  @override
  void dispose() {
    streamController?.close();
    super.dispose();
  }
}
