part of '../downloadfeature.dart';

class IdentifySubmissionState {
  final IdentifySubmissionStatus status;

  const IdentifySubmissionState(this.status);

  factory IdentifySubmissionState.idle() =>
      const IdentifySubmissionState(IdentifySubmissionStatus.idle);
  factory IdentifySubmissionState.loading() =>
      const IdentifySubmissionState(IdentifySubmissionStatus.loading);
  factory IdentifySubmissionState.success(
          IdentifiedSongDetails identifiedSongDetails) =>
      IdentifySubmissionSuccess(identifiedSongDetails);

  factory IdentifySubmissionState.failure(GenericException exception) =>
      IdentifySubmissionFailure(exception);
}

class IdentifySubmissionSuccess extends IdentifySubmissionState {
  final IdentifiedSongDetails identifiedSongDetails;
  const IdentifySubmissionSuccess(this.identifiedSongDetails)
      : super(IdentifySubmissionStatus.success);
}

class IdentifySubmissionFailure extends IdentifySubmissionState {
  final GenericException exception;

  const IdentifySubmissionFailure(this.exception)
      : super(IdentifySubmissionStatus.failure);
}

enum IdentifySubmissionStatus {
  idle,
  loading,
  success,
  failure,
}
