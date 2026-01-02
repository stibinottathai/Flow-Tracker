import 'package:p_tracker/core/utils/typedef.dart';
import 'package:p_tracker/features/example/domain/entities/example_entity.dart';

/// Example repository interface - Domain layer
abstract class ExampleRepository {
  ResultFuture<List<ExampleEntity>> getExamples();
  ResultFuture<ExampleEntity> getExampleById(String id);
  ResultFuture<void> createExample(ExampleEntity entity);
  ResultFuture<void> updateExample(ExampleEntity entity);
  ResultFuture<void> deleteExample(String id);
}
