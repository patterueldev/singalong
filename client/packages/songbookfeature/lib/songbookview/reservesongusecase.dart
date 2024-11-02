part of '../songbookfeature.dart';

abstract class ReserveSongUseCase {
  TaskEither<SongBookException, Unit> call(SongItem song);
}

class DefaultReserveSongUseCase implements ReserveSongUseCase {
  final SongRepository songRepository;

  DefaultReserveSongUseCase({
    required this.songRepository,
  });

  @override
  TaskEither<SongBookException, Unit> call(SongItem song) =>
      TaskEither.tryCatch(() async {
        await songRepository.reserveSong(song);
        return unit;
      }, (e, s) {
        if (e is SongBookException) {
          return e;
        }
        return SongBookException('Failed to reserve song');
      });
}
