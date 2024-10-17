part of '../playerfeature.dart';

abstract class PlayerViewModel {
  ValueNotifier<PlayerViewState> get playerViewStateNotifier;
  ValueNotifier<bool> get isLoadingNotifier;
  ValueNotifier<String?> get errorMessageNotifier;

  void setupSession();
}

class DefaultPlayerViewModel implements PlayerViewModel {
  final ConnectUseCase connectUseCase;
  final ListenToCurrentSongUpdatesUseCase listenToCurrentSongUpdatesUseCase;

  DefaultPlayerViewModel({
    required this.connectUseCase,
    required this.listenToCurrentSongUpdatesUseCase,
  });

  @override
  final ValueNotifier<PlayerViewState> playerViewStateNotifier =
      ValueNotifier(PlayerViewState.idle());

  @override
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);

  @override
  final ValueNotifier<String?> errorMessageNotifier = ValueNotifier(null);

  @override
  void setupSession() async {
    debugPrint('Loading video');
    isLoadingNotifier.value = true;

    // the process will be as follows:
    // 1. Connect to the server with username and roomId
    var canProceed = false;
    // TODO: THESE will probably be managed by another device in the future; for now, we'll just hardcode it
    final connectResult = await connectUseCase(
      ConnectParameters(
        username: "player",
        roomId: "569841",
        clientType: "PLAYER",
      ),
    );
    connectResult.fold(
      (l) {
        debugPrint("Error: $l");
        errorMessageNotifier.value = l.toString();
      },
      (r) {
        canProceed = true;
      },
    );

    if (!canProceed) {
      isLoadingNotifier.value = false;
      return;
    }

    // 2. Listen to the current song updates
    debugPrint("Listening to current song updates");
    listenToCurrentSongUpdatesUseCase().listen((currentSong) async {
      if (currentSong == null) {
        debugPrint("No current song");
        playerViewStateNotifier.value = PlayerViewState.idle();
      } else {
        final videoUrl = currentSong.videoURL;
        debugPrint("Playing video: $videoUrl");
        final controller = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
        );
        await controller.initialize();
        playerViewStateNotifier.value = PlayerViewState.playing(controller);

        await controller.play();
      }
    });

    // 3. Listen to the reserved songs list
    isLoadingNotifier.value = false;
  }
}

// TODO: This will be moved to a lower level package `common`
class ConnectUseCase extends ServiceUseCase<ConnectParameters, Unit> {
  final ConnectRepository connectRepository;
  ConnectUseCase({
    required this.connectRepository,
  });

  @override
  TaskEither<GenericException, Unit> task(ConnectParameters parameters) =>
      TaskEither.tryCatch(
        () async {
          debugPrint("Attempting to connect");
          if (parameters.username.isEmpty) {
            throw Exception("Name cannot be empty");
          }
          if (parameters.roomId.isEmpty) {
            throw Exception("Room ID cannot be empty");
          }

          final result = await connectRepository.connect(parameters);

          final requiresUserPasscode = result.requiresUserPasscode;
          final requiresRoomPasscode = result.requiresRoomPasscode;
          final accessToken = result.accessToken;
          if (requiresUserPasscode != null && requiresRoomPasscode != null) {
            throw GenericException.unhandled("Both passcodes required");
          } else if (accessToken != null) {
            // store the access token somewhere
            debugPrint("Access token: $accessToken");
            connectRepository.provideAccessToken(accessToken);
            return unit;
          }
          throw GenericException.unknown();
        },
        (e, s) {
          if (e is GenericException) {
            return e;
          }
          return GenericException.unhandled(e);
        },
      );
}

abstract class ConnectRepository {
  Future<ConnectResponse> connect(ConnectParameters parameters);
  void provideAccessToken(String accessToken);
}

class ConnectParameters {
  final String username;
  final String? userPasscode;
  final String roomId;
  final String? roomPasscode;
  final String clientType;

  ConnectParameters({
    required this.username,
    this.userPasscode,
    required this.roomId,
    this.roomPasscode,
    required this.clientType,
  });
}

class ConnectResponse {
  final bool? requiresUserPasscode;
  final bool? requiresRoomPasscode;
  final String? accessToken;

  ConnectResponse({
    this.requiresUserPasscode,
    this.requiresRoomPasscode,
    this.accessToken,
  });
}
