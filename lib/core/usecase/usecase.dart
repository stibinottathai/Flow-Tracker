import 'package:dartz/dartz.dart';
import 'package:p_tracker/core/error/failures.dart';
import 'package:p_tracker/core/utils/typedef.dart';

/// Base class for all use cases
/// [Type] is the return type
/// [Params] is the parameters type
abstract class UseCase<Type, Params> {
  const UseCase();

  ResultFuture<Type> call(Params params);
}

/// Use case with no parameters
abstract class UseCaseNoParams<Type> {
  const UseCaseNoParams();

  ResultFuture<Type> call();
}

/// Use case with stream return type
abstract class StreamUseCase<Type, Params> {
  const StreamUseCase();

  Stream<Either<Failure, Type>> call(Params params);
}
