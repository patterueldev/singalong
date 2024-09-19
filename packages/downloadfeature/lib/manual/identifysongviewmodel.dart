part of '../downloadfeature.dart';

abstract class IdentifySongViewModel extends ChangeNotifier {
  ValueNotifier<SubmissionResult> get submissionResultNotifier;
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
  final ValueNotifier<SubmissionResult> submissionResultNotifier =
      ValueNotifier(SubmissionResult.idle());

  @override
  String songUrl = '';

  @override
  void identifySong() async {
    submissionResultNotifier.value = SubmissionResult.loading();

    final result = await identifySongUrlUseCase(songUrl).run();

    result.fold(
      (exception) {
        submissionResultNotifier.value = SubmissionResult.failure(exception);
      },
      (details) {
        submissionResultNotifier.value = SubmissionResult.success(details);
      },
    );
  }

  @override
  void updateSongUrl(String value) {
    songUrl = value;
  }
}
