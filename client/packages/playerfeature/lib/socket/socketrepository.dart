part of '../playerfeature.dart';

abstract class SocketRepository {
  Future<void> updateSeekDuration(int durationInMilliseconds);
  Stream<int> listenSeekUpdatesInSeconds();
}
