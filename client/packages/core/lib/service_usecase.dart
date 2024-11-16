part of 'core.dart';

abstract class ServiceUseCase<P, R> {
  TaskEither<GenericException, R> task(P parameters);

  Future<Either<GenericException, R>> call(P parameters) {
    return task(parameters).run();
  }
}

abstract class MacroServiceUseCase<P, R> extends ServiceUseCase<P, R> {
  Future<R> tryTask(P parameters);
  GenericException catchException(Object e, StackTrace s) {
    if (e is GenericException) {
      return e;
    }
    return GenericException.unhandled(e);
  }

  @override
  TaskEither<GenericException, R> task(P parameters) => TaskEither.tryCatch(
        () => tryTask(parameters),
        (e, s) => catchException(e, s),
      );
}
