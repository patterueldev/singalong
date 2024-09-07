part of 'sessionfeature.dart';

abstract class SessionViewCallbackDelegate {
  void onAdded();
  void onCancel();
}

abstract class SessionNavigationDelegate {
  void openSongBook(
    BuildContext context,
    SessionViewCallbackDelegate callbackDelegate,
  );
}

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
}

class DefaultSessionViewModel extends SessionViewModel {
  final ListenToSongListUpdatesUseCase listenToSongListUpdatesUseCase;

  DefaultSessionViewModel({
    required this.listenToSongListUpdatesUseCase,
    List<ReservedSongItem>? songList,
  }) {
    if (songList != null) {
      songListNotifier.value = songList;
    }
  }

  @override
  ValueNotifier<SessionViewState> stateNotifier =
      ValueNotifier(const Initial());
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
    stateNotifier.value = const Loading();
    await Future.delayed(const Duration(seconds: 2));
    // if there's an error, we can throw an exception; use Failure state instead of Loading
    stateNotifier.value = const Loaded();

    // then start listening to changes

    listenToSongListUpdatesUseCase.execute().listen((songList) {
      songListNotifier.value = songList;
    });
  }

  @override
  void dismissSong(ReservedSongItem song) async {
    final completer = Completer<bool>();
    String title;
    String message;
    String actionText;
    if (song.currentPlaying) {
      title = 'Skip Song';
      message = 'Are you sure you want to skip this song?';
      actionText = 'Skip';
    } else {
      title = 'Cancel Song';
      message = 'Are you sure you want to cancel this song?';
      actionText = 'Cancel';
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

    // songListNotifier.value = songListNotifier.value
    //     .map((e) => e == song ? e.copyWith(currentPlaying: false) : e)
    //     .toList();
  }

  @override
  void reorderSongList(oldIndex, newIndex) {}

  @override
  void openSongDetails(ReservedSongItem song) {}

  @override
  void openSongBook() {
    isSongBookOpenNotifier.value = true;
  }
}
