part of '../downloadfeature.dart';

class SubmissionResult {
  final SubmissionStatus status;

  const SubmissionResult(this.status);

  factory SubmissionResult.idle() =>
      const SubmissionResult(SubmissionStatus.idle);
  factory SubmissionResult.loading() =>
      const SubmissionResult(SubmissionStatus.loading);
  factory SubmissionResult.success(
          IdentifiedSongDetails identifiedSongDetails) =>
      SubmissionSuccess(identifiedSongDetails);

  factory SubmissionResult.failure(GenericException exception) =>
      SubmissionFailure(exception);
}

class SubmissionSuccess extends SubmissionResult {
  final IdentifiedSongDetails identifiedSongDetails;
  const SubmissionSuccess(this.identifiedSongDetails)
      : super(SubmissionStatus.success);
}

class SubmissionFailure extends SubmissionResult {
  final GenericException exception;

  const SubmissionFailure(this.exception) : super(SubmissionStatus.failure);
}

enum SubmissionStatus {
  idle,
  loading,
  success,
  failure,
}
