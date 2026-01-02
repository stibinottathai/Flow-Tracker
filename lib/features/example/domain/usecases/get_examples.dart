import 'package:p_tracker/core/usecase/usecase.dart';
import 'package:p_tracker/core/utils/typedef.dart';
import 'package:p_tracker/features/example/domain/entities/example_entity.dart';
import 'package:p_tracker/features/example/domain/repositories/example_repository.dart';

/// Get examples use case
class GetExamples extends UseCaseNoParams<List<ExampleEntity>> {
  final ExampleRepository _repository;

  GetExamples(this._repository);

  @override
  ResultFuture<List<ExampleEntity>> call() {
    return _repository.getExamples();
  }
}
