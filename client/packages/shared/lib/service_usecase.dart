part of 'shared.dart';

abstract class ServiceUseCase<P, R> {
  TaskEither<GenericException, R> task(P parameters);

  Future<Either<GenericException, R>> call(P parameters) {
    return task(parameters).run();
  }
}
