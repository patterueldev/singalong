part of '../sessionfeature.dart';

abstract class SessionViewModel extends ChangeNotifier {
  ValueNotifier<SessionViewState> stateNotifier =
      ValueNotifier(SessionViewState.initial());
  ValueNotifier<List<ReservedSongItem>> songListNotifier = ValueNotifier([]);
  ValueNotifier<PromptModel?> promptNotifier = ValueNotifier(null);
  ValueNotifier<ReservedSongItem?> songDetailsNotifier = ValueNotifier(null);
  ValueNotifier<bool> isSongBookOpenNotifier = ValueNotifier(false);

  String get roomName;
  String? roomId;
  String get userName;

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
  final PersistenceRepository persistenceRepository;

  DefaultSessionViewModel({
    required this.reservedSongListSocketRepository,
    required this.connectRepository,
    required this.localizations,
    required this.persistenceRepository,
    List<ReservedSongItem>? songList,
  }) {
    if (songList != null) {
      songListNotifier.value = songList;
    }
  }

  String roomName = '';
  String userName = '';

  StreamController<List<ReservedSongItem>>? streamController;

  @override
  void setupSession() async {
    try {
      debugPrint('Setting up session');
      stateNotifier.value = SessionViewState.loading();
      final roomId = await persistenceRepository.getRoomId();
      if (roomId == null) {
        stateNotifier.value = SessionViewState.failure('Room ID not found');
        return;
      }
      this.roomId = roomId;
      roomName = roomId;

      final userName = await persistenceRepository.getUsername();
      if (userName == null) {
        stateNotifier.value = SessionViewState.failure('Username not found');
        return;
      }

      this.userName = userName;

      notifyListeners();
      await connectRepository.connectRoomSocket(roomId);

      debugPrint('Opening socket');
      streamController =
          reservedSongListSocketRepository.reservedSongListStreamController;
      debugPrint('Listening to stream');
      streamController?.stream.listen((songList) {
        songListNotifier.value = songList;
      });

      debugPrint('Connecting to socket');
      reservedSongListSocketRepository.requestReservedSongList();

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
  void disconnect() async {
    await connectRepository.disconnect();
    stateNotifier.value = SessionViewState.disconnected();
  }

  @override
  void dispose() {
    streamController?.close();
    super.dispose();
  }
}
