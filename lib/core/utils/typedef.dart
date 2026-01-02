import 'package:dartz/dartz.dart';
import 'package:p_tracker/core/error/failures.dart';

/// Type definition for result type using Either from dartz
typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultVoid = Future<Either<Failure, void>>;
typedef DataMap = Map<String, dynamic>;
