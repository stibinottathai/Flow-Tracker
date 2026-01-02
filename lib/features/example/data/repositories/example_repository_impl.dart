import 'package:dartz/dartz.dart';
import 'package:p_tracker/core/error/exceptions.dart';
import 'package:p_tracker/core/error/failures.dart';
import 'package:p_tracker/core/network/network_info.dart';
import 'package:p_tracker/core/utils/typedef.dart';
import 'package:p_tracker/features/example/data/datasources/example_local_datasource.dart';
import 'package:p_tracker/features/example/data/datasources/example_remote_datasource.dart';
import 'package:p_tracker/features/example/data/models/example_model.dart';
import 'package:p_tracker/features/example/domain/entities/example_entity.dart';
import 'package:p_tracker/features/example/domain/repositories/example_repository.dart';

/// Implementation of Example repository
class ExampleRepositoryImpl implements ExampleRepository {
  final ExampleRemoteDataSource _remoteDataSource;
  final ExampleLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  ExampleRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  );

  @override
  ResultFuture<List<ExampleEntity>> getExamples() async {
    try {
      if (await _networkInfo.isConnected) {
        final examples = await _remoteDataSource.getExamples();
        await _localDataSource.cacheExamples(examples);
        return Right(_mapModelsToEntities(examples));
      } else {
        final cachedExamples = await _localDataSource.getCachedExamples();
        return Right(_mapModelsToEntities(cachedExamples));
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<ExampleEntity> getExampleById(String id) async {
    try {
      final example = await _remoteDataSource.getExampleById(id);
      return Right(_mapModelToEntity(example));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<void> createExample(ExampleEntity entity) async {
    try {
      final model = _mapEntityToModel(entity);
      await _remoteDataSource.createExample(model);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<void> updateExample(ExampleEntity entity) async {
    try {
      final model = _mapEntityToModel(entity);
      await _remoteDataSource.updateExample(model);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  ResultFuture<void> deleteExample(String id) async {
    try {
      await _remoteDataSource.deleteExample(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  // Helper methods to map between models and entities
  List<ExampleEntity> _mapModelsToEntities(List<ExampleModel> models) {
    return models.map(_mapModelToEntity).toList();
  }

  ExampleEntity _mapModelToEntity(ExampleModel model) {
    return ExampleEntity(
      id: model.id,
      title: model.title,
      description: model.description,
      createdAt: model.createdAt,
    );
  }

  ExampleModel _mapEntityToModel(ExampleEntity entity) {
    return ExampleModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      createdAt: entity.createdAt,
    );
  }
}
