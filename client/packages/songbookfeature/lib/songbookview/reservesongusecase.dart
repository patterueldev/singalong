part of '../songbookfeature.dart';

abstract class ReserveSongUseCase {
  TaskEither<GenericException, Unit> call(SongbookItem song);
}

class DefaultReserveSongUseCase implements ReserveSongUseCase {
  final SongRepository songRepository;

  DefaultReserveSongUseCase({
    required this.songRepository,
  });

  @override
  TaskEither<GenericException, Unit> call(SongbookItem song) =>
      TaskEither.tryCatch(() async {
        await songRepository.reserveSong(song);
        return unit;
      }, (e, s) {
        if (e is GenericException) {
          return e;
        }
        return GenericException.unhandled(e);
      });
}
