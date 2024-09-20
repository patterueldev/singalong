part of '../downloadfeature.dart';

abstract class IdentifySongViewModel extends ChangeNotifier {
  ValueNotifier<IdentifySubmissionState> get submissionStateNotifier;
  String get songUrl;

  void identifySong();
  void updateSongUrl(String value);
}

class DefaultIdentifySongViewModel extends IdentifySongViewModel {
  final IdentifySongUrlUseCase identifySongUrlUseCase;

  DefaultIdentifySongViewModel({
    required this.identifySongUrlUseCase,
  });

  @override
  final ValueNotifier<IdentifySubmissionState> submissionStateNotifier =
      ValueNotifier(IdentifySubmissionState.idle());

  @override
  String songUrl = '';

  @override
  void identifySong() async {
    submissionStateNotifier.value = IdentifySubmissionState.loading();

    final result = await identifySongUrlUseCase(songUrl).run();

    result.fold(
      (exception) {
        submissionStateNotifier.value =
            IdentifySubmissionState.failure(exception);
      },
      (details) {
        submissionStateNotifier.value =
            IdentifySubmissionState.success(details);
      },
    );
  }

  @override
  void updateSongUrl(String value) {
    songUrl = value;
  }
}
